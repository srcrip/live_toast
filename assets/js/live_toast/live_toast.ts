import { animate } from 'motion'
import type { Easing } from 'motion'
import type { ViewHook } from 'phoenix_live_view'

function isHidden(el: HTMLElement | null) {
  if (el === null) {
    return true
  }

  return el.offsetParent === null
}

function isFlash(el: HTMLElement) {
  return el.dataset.component === 'flash'
}

// number of flashes that aren't hidden
function flashCount() {
  let num = 0

  if (!isHidden(document.getElementById('server-error'))) {
    num += 1
  }

  if (!isHidden(document.getElementById('client-error'))) {
    num += 1
  }

  if (!isHidden(document.getElementById('flash-info'))) {
    num += 1
  }

  if (!isHidden(document.getElementById('flash-error'))) {
    num += 1
  }

  return num
}

// time in ms to wait before removal, but after animation
const removalTime = 5
// whether flashes should be counted in maxItems
const maxItemsIgnoresFlashes = true
// gap in px between toasts
const gap = 15
const dismissEvent = 'live-toast-dismiss'
const remainingSelector = '[data-live-toast-remaining]'

let lastTS: HTMLElement[] = []

type DismissTimer = {
  cancel: () => void
}

const dismissTimers = new WeakMap<object, DismissTimer>()

type MotionDirection = 'auto' | 'up' | 'down' | 'left' | 'right' | 'none'
type MotionPhase = {
  direction: MotionDirection
  duration: number
  easing: Easing
}
type MotionConfig = {
  enter: MotionPhase
  exit: MotionPhase
}

const defaultMotion: MotionConfig = {
  enter: {
    direction: 'auto',
    duration: 550,
    easing: [0.22, 1, 0.36, 1]
  },
  exit: {
    direction: 'auto',
    duration: 300,
    easing: 'ease-out'
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null
}

function isDirection(value: unknown): value is MotionDirection {
  return ['auto', 'up', 'down', 'left', 'right', 'none'].includes(
    value as MotionDirection
  )
}

function isEasing(value: unknown): value is Easing {
  if (Array.isArray(value)) {
    return value.length === 4 && value.every(item => typeof item === 'number')
  }

  return (
    typeof value === 'string' &&
    (['linear', 'ease', 'ease-in', 'ease-out', 'ease-in-out'].includes(value) ||
      /^steps\(\d+, (start|end)\)$/.test(value))
  )
}

function normalizeMotionPhase(
  value: unknown,
  defaults: MotionPhase
): MotionPhase {
  if (!isRecord(value)) {
    return defaults
  }

  return {
    direction: isDirection(value.direction)
      ? value.direction
      : defaults.direction,
    duration:
      typeof value.duration === 'number' && value.duration >= 0
        ? value.duration
        : defaults.duration,
    easing: isEasing(value.easing) ? value.easing : defaults.easing
  }
}

function motionConfig(el: HTMLElement): MotionConfig {
  const host = el.closest<HTMLElement>('[data-live-toast-motion]')
  const encoded = host?.dataset.liveToastMotion

  if (!encoded) {
    return defaultMotion
  }

  try {
    const value: unknown = JSON.parse(encoded)

    if (!isRecord(value)) {
      return defaultMotion
    }

    return {
      enter: normalizeMotionPhase(value.enter, defaultMotion.enter),
      exit: normalizeMotionPhase(value.exit, defaultMotion.exit)
    }
  } catch {
    return defaultMotion
  }
}

function reducedMotion() {
  return (
    window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false
  )
}

function resolvedDirection(
  direction: MotionDirection,
  corner: string | undefined
) {
  if (direction !== 'auto') {
    return direction
  }

  return corner?.startsWith('bottom') ? 'down' : 'up'
}

function translation(
  direction: MotionDirection,
  corner: string | undefined,
  distance: number
) {
  switch (resolvedDirection(direction, corner)) {
    case 'up':
      return { y: `-${distance}px` }
    case 'down':
      return { y: `${distance}px` }
    case 'left':
      return { x: `-${distance}px` }
    case 'right':
      return { x: `${distance}px` }
    default:
      return {}
  }
}

function translatedY(destination: string, offset: string) {
  return destination === '0px' ? offset : `calc(${destination} + ${offset})`
}

declare global {
  interface HTMLElement {
    order: number
    targetDestination: string
  }
}

function doAnimations(
  this: ViewHook,
  animationDelayTime: number,
  maxItems: number,
  elToRemove?: HTMLElement
) {
  const ts = []
  let toasts = Array.from(
    document.querySelectorAll<HTMLElement>(
      '#toast-group [phx-hook="LiveToast"]'
    )
  )
    .map(t => {
      if (isHidden(t)) {
        return null
      }

      return t
    })
    .filter(Boolean)
    // reverse
    .reverse()

  if (elToRemove) {
    toasts = toasts.filter(t => t !== elToRemove)
  }

  // Traverse through all toasts, in order they appear in the dom, for which they are NOT hidden, and assign el.order to
  // their index
  for (let i = 0; i < toasts.length; i++) {
    const toast = toasts[i]!
    if (isHidden(toast)) {
      continue
    }
    toast.order = i

    ts[i] = toast
  }

  // now loop through ts and animate each toast to its position
  for (let i = 0; i < ts.length; i++) {
    const max = maxItemsIgnoresFlashes ? maxItems + flashCount() : maxItems

    const toast = ts[i]

    let direction = ''

    if (
      toast.dataset.corner === 'bottom_left' ||
      toast.dataset.corner === 'bottom_center' ||
      toast.dataset.corner === 'bottom_right'
    ) {
      direction = '-'
    }

    // Calculate the translateY value with gap
    // now that they can be different heights, we need to actually caluclate the real heights and add them up.
    let val = 0

    for (let j = 0; j < toast.order; j++) {
      val += ts[j].offsetHeight + gap
    }

    // Calculate opacity based on position
    const opacity = toast.order > max ? 0 : 1 - (toast.order - max + 1)

    // also if this item moved past the max limit, disable click events on it
    if (toast.order >= max) {
      toast.classList.remove('pointer-events-auto')
    } else {
      toast.classList.add('pointer-events-auto')
    }

    const destination = val === 0 ? '0px' : `${direction}${val}px`
    const keyframes: Record<string, Array<string | number>> = {
      y: [destination],
      opacity: [opacity]
    }

    // if element is entering for the first time, start below the fold
    if (toast.order === 0 && lastTS.includes(toast) === false) {
      const enter = motionConfig(toast).enter

      if (!reducedMotion()) {
        const offset = translation(
          enter.direction,
          toast.dataset.corner,
          toast.offsetHeight + gap
        )

        if (offset.y) {
          keyframes.y.unshift(translatedY(destination, offset.y))
        }

        if (offset.x) {
          keyframes.x = [offset.x, '0px']
        }
      }

      keyframes.opacity.unshift(0)
    }

    toast.targetDestination = destination
    const enter = motionConfig(toast).enter

    const delayTime = Number.parseInt(this.el.dataset.delay || '0') / 1000

    animate(toast, keyframes, {
      duration: reducedMotion() ? 0.001 : enter.duration / 1000,
      easing: reducedMotion() ? 'linear' : enter.easing,
      delay: delayTime
    })
    toast.order += 1

    // decrease z-index
    toast.style.zIndex = (50 - toast.order).toString()

    // if this element moved past the max item limit, send the signal to remove it
    // should this be shorted than delay time?
    // also what about elements moving down when you close one?
    window.setTimeout(() => {
      if (toast.order > max) {
        toast.dispatchEvent(new CustomEvent(dismissEvent))
      }
    }, animationDelayTime + removalTime)

    lastTS = ts
  }
}

function toastGroupTarget(el: HTMLElement) {
  const streamContainer = el.closest<HTMLElement>('[phx-update="stream"]')
  const toastGroup = streamContainer?.parentElement

  return toastGroup || '#toast-group'
}

async function animateOut(this: ViewHook) {
  const exit = motionConfig(this.el).exit
  const offset = translation(
    exit.direction,
    this.el.dataset.corner,
    this.el.offsetHeight + gap
  )
  const keyframes: Record<string, string | number> = { opacity: 0 }

  if (!reducedMotion()) {
    if (offset.y) {
      keyframes.y = translatedY(this.el.targetDestination || '0px', offset.y)
    }

    if (offset.x) {
      keyframes.x = offset.x
    }
  }

  const animation = animate(this.el, keyframes, {
    duration: reducedMotion() ? 0.001 : exit.duration / 1000,
    easing: reducedMotion() ? 'linear' : exit.easing
  })

  await animation.finished
}

async function dismissToast(
  this: ViewHook,
  animationDelayTime: number,
  maxItems: number
) {
  if (this.el.dataset.liveToastDismissing === 'true') {
    return
  }

  this.el.dataset.liveToastDismissing = 'true'
  dismissTimers.get(this)?.cancel()
  dismissTimers.delete(this)

  doAnimations.bind(this, animationDelayTime, maxItems, this.el)()
  await animateOut.bind(this)()

  this.pushEventTo(toastGroupTarget(this.el), 'clear', { id: this.el.id })
}

function isInteracting(el: HTMLElement) {
  return el.matches(':hover') || el.matches(':focus-within')
}

function renderRemaining(el: HTMLElement, remaining: number, paused: boolean) {
  const output = el.querySelector<HTMLElement>(remainingSelector)

  if (!output) {
    return
  }

  output.textContent = Math.ceil(remaining / 1000).toString()
  output.dataset.paused = paused.toString()
}

function startDismissTimer(
  this: ViewHook,
  duration: number,
  animationDelayTime: number,
  maxItems: number
) {
  let remaining = duration
  let startedAt: number | undefined
  let timer: number | undefined
  let displayTimer: number | undefined

  const currentRemaining = () => {
    if (startedAt === undefined) {
      return remaining
    }

    return Math.max(0, remaining - (performance.now() - startedAt))
  }

  const clearTimers = () => {
    if (timer !== undefined) {
      window.clearTimeout(timer)
      timer = undefined
    }

    if (displayTimer !== undefined) {
      window.clearInterval(displayTimer)
      displayTimer = undefined
    }
  }

  const pause = () => {
    if (startedAt === undefined) {
      return
    }

    remaining = currentRemaining()
    startedAt = undefined
    clearTimers()
    renderRemaining(this.el, remaining, true)
  }

  const resume = () => {
    if (timer || isInteracting(this.el)) {
      return
    }

    startedAt = performance.now()
    renderRemaining(this.el, remaining, false)

    if (this.el.querySelector(remainingSelector)) {
      displayTimer = window.setInterval(() => {
        renderRemaining(this.el, currentRemaining(), false)
      }, 100)
    }

    timer = window.setTimeout(async () => {
      clearTimers()
      remaining = 0
      startedAt = undefined
      renderRemaining(this.el, remaining, false)

      await dismissToast.bind(this)(animationDelayTime, maxItems)
    }, remaining + removalTime)
  }

  const cancel = () => {
    clearTimers()
    this.el.removeEventListener('mouseenter', pause)
    this.el.removeEventListener('focusin', pause)
    this.el.removeEventListener('mouseleave', resume)
    this.el.removeEventListener('focusout', resume)
  }

  this.el.addEventListener('mouseenter', pause)
  this.el.addEventListener('focusin', pause)
  this.el.addEventListener('mouseleave', resume)
  this.el.addEventListener('focusout', resume)

  dismissTimers.set(this, { cancel })
  resume()
}

// Create the Phoenix Hoook for live_toast.
// You can set custom animation durations.
export function createLiveToastHook(duration = 6000, maxItems = 3) {
  return {
    destroyed(this: ViewHook) {
      dismissTimers.get(this)?.cancel()
      dismissTimers.delete(this)
      doAnimations.bind(this)(duration, maxItems)
    },
    updated(this: ViewHook) {
      // animate to targetDestination in 0ms
      const keyframes = { y: [this.el.targetDestination] }
      animate(this.el, keyframes, { duration: 0 })
    },
    mounted(this: ViewHook) {
      this.el.addEventListener('show-error', async _event => {
        const delayTime = Number.parseInt(this.el.dataset.delay || '0')
        await new Promise(resolve => setTimeout(resolve, delayTime))

        // todo: in the future use this to execute the data-disconnected command
        // https://elixirforum.com/t/can-we-use-liveview-js-commands-inside-a-hook/67324/8

        // const command = this.el.getAttribute('data-disconnected')
        // this.liveSocket.execJS(this.el, command)

        // (don't want to do this quite yet because 1.0 is pretty new)
        // also repeat this on hide.

        this.el.style.display = 'flex'
      })

      this.el.addEventListener('hide-error', async _event => {
        this.el.style.display = 'none'
      })

      // for the special flashes, check if they are visible, and if not, return early out of here.
      if (['server-error', 'client-error'].includes(this.el.id)) {
        if (isHidden(document.getElementById(this.el.id))) {
          return
        }
      }

      window.addEventListener('phx:clear-flash', e => {
        this.pushEvent('lv:clear-flash', {
          key: (e as CustomEvent<{ key: string }>).detail.key
        })
      })

      window.addEventListener('flash-leave', async event => {
        if (event.target === this.el) {
          // animate this flash sliding out
          doAnimations.bind(this, duration, maxItems, this.el)()
          await animateOut.bind(this)()
        }
      })

      this.el.addEventListener(dismissEvent, async event => {
        event.stopPropagation()

        await dismissToast.bind(this)(duration, maxItems)
      })

      window.addEventListener(`phx:${dismissEvent}`, async event => {
        const detail = (event as CustomEvent<{ id?: string; uuid?: string }>)
          .detail
        const id = detail.id || `toast-${detail.uuid}`

        if (id === this.el.id) {
          await dismissToast.bind(this)(duration, maxItems)
        }
      })

      // begin actually showing the toast through this call to the animation function
      doAnimations.bind(this)(duration, maxItems)

      let durationOverride = duration
      if (this.el.dataset.duration !== undefined) {
        durationOverride = Number.parseInt(this.el.dataset.duration)
      }

      let flashDuration = undefined
      if (this.el.dataset.flashDuration !== undefined) {
        flashDuration = Number.parseInt(this.el.dataset.flashDuration)
      }

      // skip the removal code if this is a flash, if autoHideFlash is nullish
      if (isFlash(this.el) && !flashDuration) {
        return
      }

      // this could be condensed
      if (flashDuration) {
        // do stuff
        window.setTimeout(async () => {
          // animate this element sliding down, opacity to 0, with delay time
          await animateOut.bind(this)()

          const kind = this.el.dataset.kind

          if (kind) {
            this.pushEvent('lv:clear-flash', { key: kind })
          }
        }, flashDuration + removalTime)
      } else {
        // you can set duration to 0 for infinite duration, basically
        if (durationOverride !== 0) {
          startDismissTimer.bind(this)(durationOverride, duration, maxItems)
        }
      }
    }
  }
}
