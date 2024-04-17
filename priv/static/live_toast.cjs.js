var __defProp = Object.defineProperty;
var __markAsModule = (target) => __defProp(target, "__esModule", { value: true });
var __export = (target, all) => {
  __markAsModule(target);
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};

// js/live_toast/index.ts
__export(exports, {
  createLiveToastHook: () => createLiveToastHook
});

// js/live_toast/live_toast.ts
function createLiveToastHook(duration = 6e3, enterAnimationTime = 400, leaveAnimationTime = 600) {
  return {
    mounted() {
      let dataDuration = this.el.dataset.duration;
      if (dataDuration !== void 0) {
        duration = parseInt(dataDuration);
      }
      let ty;
      if (this.el.dataset.corner === "bottom-left" || this.el.dataset.corner === "bottom-right") {
        ty = "-100px";
      } else {
        ty = "100px";
      }
      this.el.animate([
        { opacity: 0, transform: `translateY(${ty}) rotateY(30deg)` },
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
          transform: "scale(0) rotateY(30deg)",
          height: 0,
          color: "transparent",
          background: "transparent",
          padding: 0
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
      }, duration + 5);
    }
  };
}
//# sourceMappingURL=live_toast.cjs.js.map
