import { animate } from 'motion'
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
// animation time in ms
const animationTime = 550
// whether flashes should be counted in maxItems
const maxItemsIgnoresFlashes = true
// gap in px between toasts
const gap = 15

let lastTS: any[] = []

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
      } else {
        return t
      }
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

    const keyframes = { y: [`${direction}${val}px`], opacity: [opacity] }

    // if element is entering for the first time, start below the fold
    if (toast.order === 0 && lastTS.includes(toast) === false) {
      const val = toast.offsetHeight + gap
      const oppositeDirection = direction === '-' ? '' : '-'
      keyframes.y.unshift(`${oppositeDirection}${val}px`)

      keyframes.opacity.unshift(0)
    }

    toast.targetDestination = `${direction}${val}px`

    const duration = animationTime / 1000

    // as of right now this is not exposed to end users, but
    // it's 'plumbed out' if we want to make it so in the future
    const delayTime = Number.parseInt(this.el.dataset.delay || '0') / 1000

    animate(toast, keyframes, {
      duration,
      easing: [0.22, 1.0, 0.36, 1.0],
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
        this.pushEventTo('#toast-group', 'clear', { id: toast.id })
      }
    }, animationDelayTime + removalTime)

    lastTS = ts
  }
}

async function animateOut(this: ViewHook) {
  const val = (this.el.order - 2) * 100 + (this.el.order - 2) * gap

  let direction = ''

  if (
    this.el.dataset.corner === 'bottom_left' ||
    this.el.dataset.corner === 'bottom_center' ||
    this.el.dataset.corner === 'bottom_right'
  ) {
    direction = '-'
  }

  const animation = animate(
    this.el,
    { y: `${direction}${val}%`, opacity: 0 },
    {
      opacity: {
        duration: 0.2,
        easing: 'ease-out'
      },
      duration: 0.3,
      easing: 'ease-out'
    }
  )

  await animation.finished
}

// Create the Phoenix Hoook for live_toast.
// You can set custom animation durations.
export function createLiveToastHook(duration = 6000, maxItems = 3) {
  return {
    destroyed(this: ViewHook) {
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
          window.setTimeout(async () => {
            // animate this element sliding down, opacity to 0, with delay time
            await animateOut.bind(this)()

            this.pushEventTo('#toast-group', 'clear', { id: this.el.id })
          }, durationOverride + removalTime)
        }
      }
    }
  }
}
