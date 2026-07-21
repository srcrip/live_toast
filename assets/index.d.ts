import type { ViewHook } from '../deps/phoenix_live_view'

declare const createLiveToastHook: () => ViewHook

type ClientToastOptions = {
  duration?: number | 'infinity'
  metadata?: Record<string, unknown>
  title?: string
}

declare function addToast(
  kind: string,
  message: string,
  options?: ClientToastOptions
): void

export { addToast, ClientToastOptions, createLiveToastHook }
