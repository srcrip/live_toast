import test from 'ava'
import { createLiveToastHook } from './js/live_toast/live_toast.ts'

class ViewHookTest {
  constructor(hook, element) {
    this.el = element
    this.__callbacks = hook
    for (let key in this.__callbacks) {
      this[key] = this.__callbacks[key]
    }
  }

  trigger(callbackName) {
    this.__callbacks[callbackName].bind(this)()
  }

  pushEvent(_event, _payload) {}
  pushEvent(_target, _event, _payload) {}

  element() {
    return this.el
  }
}
function createElementFromHTML(htmlString) {
  const div = document.createElement('div')
  div.innerHTML = htmlString.trim()
  return div.firstChild
}

function renderHook(htmlString, hook) {
  const element = createElementFromHTML(htmlString)
  return new ViewHookTest(hook, element)
}

test('hook', () => {
  const LiveToast = createLiveToastHook()
  const hook = renderHook('<div>Old content</div>', LiveToast)
  hook.trigger('mounted')
  expect(hook.element().textContent).toEqual('New content')
})

test('foo', t => {
  t.pass()
})

test('bar', async t => {
  const bar = Promise.resolve('bar')
  t.is(await bar, 'bar')
})
