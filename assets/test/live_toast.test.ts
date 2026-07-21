import {
  afterEach,
  beforeEach,
  describe,
  expect,
  jest,
  mock,
  test
} from 'bun:test'
import { JSDOM } from 'jsdom'

const animationEvents: string[] = []

mock.module('motion', () => ({
  animate: () => {
    animationEvents.push('animate')
    return { finished: Promise.resolve() }
  }
}))

const { createLiveToastHook } = await import('../js/live_toast/live_toast.ts')

type MountedToast = ReturnType<typeof mountToast>

let now = 0

function installDom() {
  const dom = new JSDOM('<!doctype html><html><body></body></html>', {
    url: 'http://localhost'
  })

  Object.assign(globalThis, {
    window: dom.window,
    document: dom.window.document,
    CustomEvent: dom.window.CustomEvent,
    Event: dom.window.Event,
    HTMLElement: dom.window.HTMLElement
  })

  dom.window.setTimeout = globalThis.setTimeout
  dom.window.clearTimeout = globalThis.clearTimeout
  dom.window.setInterval = globalThis.setInterval
  dom.window.clearInterval = globalThis.clearInterval

  Object.defineProperty(globalThis.performance, 'now', {
    configurable: true,
    value: () => now
  })

  return dom
}

function mountToast(duration: number | 'Infinity' = 1000, countdown = false) {
  document.body.innerHTML = `
    <div id="toast-group">
      <div id="toast-stream" phx-update="stream">
        <div
          id="toast-one"
          phx-hook="LiveToast"
          data-corner="bottom_right"
          data-duration="${duration}"
        >
          <button type="button">Focus me</button>
          ${countdown ? '<span data-live-toast-remaining></span>' : ''}
        </div>
      </div>
    </div>
  `

  const el = document.getElementById('toast-one') as HTMLElement
  const group = document.getElementById('toast-group') as HTMLElement
  const pushes: Array<[Element | string, string, Record<string, string>]> = []
  let hovered = false
  let focused = false

  Object.defineProperty(el, 'offsetParent', {
    configurable: true,
    get: () => document.body
  })

  el.order = 1
  el.targetDestination = '0px'
  el.matches = ((selector: string) => {
    if (selector === ':hover') return hovered
    if (selector === ':focus-within') return focused
    return false
  }) as typeof el.matches

  const callbacks = createLiveToastHook(1000, 3)
  const hook = {
    el,
    pushEvent: () => undefined,
    pushEventTo: (
      target: Element | string,
      event: string,
      payload: Record<string, string>
    ) => {
      animationEvents.push(event)
      pushes.push([target, event, payload])
    }
  }

  callbacks.mounted.call(hook as never)

  return {
    callbacks,
    el,
    group,
    hook,
    pushes,
    setFocused(value: boolean) {
      focused = value
      el.dispatchEvent(new Event(value ? 'focusin' : 'focusout'))
    },
    setHovered(value: boolean) {
      hovered = value
      el.dispatchEvent(new Event(value ? 'mouseenter' : 'mouseleave'))
    }
  }
}

function advance(milliseconds: number) {
  now += milliseconds
  jest.advanceTimersByTime(milliseconds)
}

async function settle() {
  await Promise.resolve()
  await Promise.resolve()
}

describe('LiveToast timed dismissal', () => {
  beforeEach(() => {
    jest.useFakeTimers()
    now = 0
    animationEvents.length = 0
    installDom()
  })

  afterEach(() => {
    jest.useRealTimers()
  })

  test('expires through the animated dismissal path', async () => {
    const toast = mountToast()
    animationEvents.length = 0

    advance(1005)
    await settle()

    expect(animationEvents).toEqual(['animate', 'clear'])
    expect(toast.pushes[0]?.[2]).toEqual({ id: 'toast-one' })
    expect(toast.pushes[0]?.[0]).toBe(toast.group)
  })

  test('pauses on hover and resumes with the remaining duration', async () => {
    const toast = mountToast(1000, true)

    advance(400)
    toast.setHovered(true)
    advance(2000)

    expect(toast.pushes).toHaveLength(0)
    expect(toast.el.querySelector(remainingSelector)?.textContent).toBe('1')

    toast.setHovered(false)
    advance(604)
    expect(toast.pushes).toHaveLength(0)

    advance(1)
    await settle()
    expect(toast.pushes).toHaveLength(1)
  })

  test('waits for both focus and hover interaction to end', async () => {
    const toast = mountToast()

    advance(250)
    toast.setFocused(true)
    toast.setHovered(true)
    toast.setFocused(false)
    advance(2000)

    expect(toast.pushes).toHaveLength(0)

    toast.setHovered(false)
    advance(755)
    await settle()
    expect(toast.pushes).toHaveLength(1)
  })

  test('does not schedule dismissal for a persistent toast', () => {
    const toast = mountToast(0)

    advance(60_000)

    expect(toast.pushes).toHaveLength(0)
  })

  test('does not schedule dismissal for an Infinity duration', () => {
    const toast = mountToast('Infinity')

    advance(60_000)

    expect(toast.pushes).toHaveLength(0)
  })

  test('cancels dismissal when the hook is destroyed', () => {
    const toast = mountToast()

    toast.callbacks.destroyed.call(toast.hook as never)
    advance(60_000)

    expect(toast.pushes).toHaveLength(0)
  })

  test('animates before clearing on programmatic dismissal', async () => {
    const toast = mountToast()
    animationEvents.length = 0

    window.dispatchEvent(
      new CustomEvent('phx:live-toast-dismiss', {
        detail: { uuid: 'one' }
      })
    )
    await settle()

    expect(animationEvents).toEqual(['animate', 'clear'])
    expect(toast.pushes).toHaveLength(1)
  })

})

const remainingSelector = '[data-live-toast-remaining]'
