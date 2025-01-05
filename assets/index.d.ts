import type { ViewHook } from '../deps/phoenix_live_view'

declare const createLiveToastHook: () => ViewHook

declare global {
  interface Window {
    addToast: (kind: string, msg: string, options?: Options) => void
  }
}

export { createLiveToastHook }
