import type { ViewHook } from 'phoenix_live_view'

// Create the Phoenix Hoook for live_toast.
// You can set custom animation durations.
export function createLiveToastHook(
  duration: number = 6000,
  enterAnimationTime: number = 400,
  leaveAnimationTime: number = 600,
) {
  return {
    mounted(this: ViewHook) {
      let dismissTime = this.el.dataset.dismiss
      if (dismissTime !== undefined) {
        duration = parseInt(dismissTime)
      }

      this.el.animate(
        [
          { opacity: 0, transform: 'translateY(-100px) rotateY(30deg)' },
          { opacity: 1, transform: 'translateY(0px) rotateY(0deg)' },
        ],
        {
          duration: enterAnimationTime,
          easing: 'cubic-bezier(0, 0, 0.2, 1.0)',
          fill: 'forwards',
        },
      )

      // don't remove the special error flashes automatically
      // or toasts with dismissTime set to 0
      const specialToasts = ['server-error', 'client-error']
      if (specialToasts.includes(this.el.id) || duration === 0) {
        return
      }

      const keyframes = [
        {
          opacity: 1,
          height: 'auto',
        },
        {
          opacity: 0,
          transform: 'scale(.95) rotateY(30deg)',
          height: 0,
          color: 'transparent',
          background: 'transparent',
          padding: '0 .6em',
          margin: '0 .3em',
        },
      ]

      this.el.animate(keyframes, {
        delay: duration - leaveAnimationTime,
        duration: leaveAnimationTime,
        fill: 'forwards',
        easing: 'cubic-bezier(0, 0, 0.5, 1.0)',
      })

      // remove the toast from the server 50ms after the animation ends
      // NOTE: this probably doesn't even need to happen, could just leave them on the socket.
      //       if there's problems this might just get removed, I don't know
      window.setTimeout(() => {
        this.pushEventTo('#toast-group', 'clear', { id: this.el.id })
      }, duration + 50)
    },
  }
}
