import type { ViewHook } from 'phoenix_live_view'
import { animate } from 'motion'

function isHidden(el: HTMLElement | null) {
  if (el === null) {
    return true
  }

  return el.offsetParent === null
}

function isFlash(el: HTMLElement) {
  if (
    ['server-error', 'client-error', 'flash-info', 'flash-error'].includes(
      el.id,
    )
  ) {
    return true
  } else {
    return false
  }
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
// max toasts of one kind (flashes don't count)
const maxItems = 3
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
  delayTime: number,
  elToRemove?: HTMLElement,
) {
  const ts = []
  let toasts = Array.from(
    document.querySelectorAll<HTMLElement>('#toast-group > div'),
  )
    .map((t) => {
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
    toasts = toasts.filter((t) => t !== elToRemove)
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

    let keyframes = { y: [`${direction}${val}px`], opacity: [opacity] }

    // if element is entering for the first time, start below the fold
    if (toast.order === 0 && lastTS.includes(toast) === false) {
      const val = toast.offsetHeight + gap
      const oppositeDirection = direction === '-' ? '' : '-'
      keyframes.y.unshift(`${oppositeDirection}${val}px`)

      keyframes.opacity.unshift(0)
    }

    toast.targetDestination = `${direction}${val}px`

    const duration = animationTime / 1000

    animate(toast, keyframes, {
      duration,
      easing: [0.22, 1.0, 0.36, 1.0],
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
    }, delayTime + removalTime)

    lastTS = ts
  }
}

async function animateOut(this: ViewHook) {
  const val = (this.el.order - 2) * 100 + (this.el.order - 2) * gap

  let direction = ''

  if (
    this.el.dataset.corner === 'bottom_left' ||
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
        easing: 'ease-out',
      },
      duration: 0.3,
      easing: 'ease-out',
    },
  )

  await animation.finished
}

// Create the Phoenix Hoook for live_toast.
// You can set custom animation durations.
export function createLiveToastHook(duration = 6000) {
  return {
    destroyed(this: ViewHook) {
      doAnimations.bind(this)(duration)
    },
    updated(this: ViewHook) {
      console.log(`updated ${this.el.id}`)
      console.log(this.el.targetDestination)

      // animate to targetDestination in 0ms
      let keyframes = { y: [this.el.targetDestination] }
      animate(this.el, keyframes, { duration: 0 })
    },
    mounted(this: ViewHook) {
      // for the special flashes, check if they are visible, and if not, return early out of here.
      if (['server-error', 'client-error'].includes(this.el.id)) {
        if (isHidden(document.getElementById(this.el.id))) {
          return
        }
      }

      window.addEventListener('flash-leave', async (event) => {
        if (event.target === this.el) {
          // animate this flash sliding out
          doAnimations.bind(this, duration, this.el)()
          await animateOut.bind(this)()
        }
      })

      doAnimations.bind(this)(duration)

      // skip the removal code if this is a flash
      if (isFlash(this.el)) {
        return
      }

      let durationOverride = duration
      if (this.el.dataset.duration !== undefined) {
        durationOverride = parseInt(this.el.dataset.duration)
      }

      window.setTimeout(async () => {
        // animate this element sliding down, opacity to 0, with delay time
        await animateOut.bind(this)()

        this.pushEventTo('#toast-group', 'clear', { id: this.el.id })
      }, durationOverride + removalTime)
    },
  }
}
