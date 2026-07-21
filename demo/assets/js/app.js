import 'phoenix_html'
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import {
  addToast,
  createLiveToastHook
} from '../../../assets/js/live_toast/live_toast.ts'

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')
let liveSocket = new LiveSocket('/live', Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: { LiveToast: createLiveToastHook() },
})

// connect if there are any LiveViews on the page
liveSocket.connect()

window.addEventListener('phx:close-menu', (e) => {
  const menu = document.querySelector('aside#main-navigation')
  menu.classList.remove('max-md:block')

  const backdrop = document.querySelector('#backdrop')
  backdrop.classList.remove('max-md:block')
})

document.addEventListener('click', event => {
  if (!(event.target instanceof Element)) {
    return
  }

  const trigger = event.target.closest('[data-client-toast-example]')

  if (!trigger) {
    return
  }

  addToast('info', 'This toast was requested from browser JavaScript.', {
    metadata: { source: 'demo' },
    title: 'Client-side toast'
  })
})

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
