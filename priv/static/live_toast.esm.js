// js/live_toast/live_toast.ts
function createLiveToastHook(duration = 6e3, enterAnimationTime = 400, leaveAnimationTime = 600) {
  return {
    mounted() {
      let dismissTime = this.el.dataset.dismiss;
      if (dismissTime !== void 0) {
        duration = parseInt(dismissTime);
      }
      this.el.animate([
        { opacity: 0, transform: "translateY(-100px) rotateY(30deg)" },
        { opacity: 1, transform: "translateY(0px) rotateY(0deg)" }
      ], {
        duration: enterAnimationTime,
        easing: "cubic-bezier(0, 0, 0.2, 1.0)",
        fill: "forwards"
      });
      const specialToasts = ["server-error", "client-error"];
      if (specialToasts.includes(this.el.id) || duration === 0) {
        return;
      }
      const keyframes = [
        {
          opacity: 1,
          height: "auto"
        },
        {
          opacity: 0,
          transform: "scale(.95) rotateY(30deg)",
          height: 0,
          color: "transparent",
          background: "transparent",
          padding: "0 .6em",
          margin: "0 .3em"
        }
      ];
      this.el.animate(keyframes, {
        delay: duration - leaveAnimationTime,
        duration: leaveAnimationTime,
        fill: "forwards",
        easing: "cubic-bezier(0, 0, 0.5, 1.0)"
      });
      window.setTimeout(() => {
        this.pushEventTo("#toast-group", "clear", { id: this.el.id });
      }, duration + 50);
    }
  };
}
export {
  createLiveToastHook
};
//# sourceMappingURL=live_toast.esm.js.map
