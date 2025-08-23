function _parseHexColor(hex) {
  const match = hex.replace("#", "").match(/^([a-f\d]{3}|[a-f\d]{6})$/i);
  if (!match) throw new Error("Invalid hex color format");
  let hexValue = match[1];
  if (hexValue.length === 3) {
    hexValue = hexValue.split("").map((c) => c + c).join("");
  }
  const value = parseInt(hexValue, 16);
  const r = value >> 16 & 255;
  const g = value >> 8 & 255;
  const b = value & 255;
  return [r, g, b];
}
function _parseFocalPointCoordinate(focalPoint) {
  const normalizedFocalPoint = focalPoint.trim().toLowerCase();
  if (normalizedFocalPoint.endsWith("%"))
    return parseFloat(normalizedFocalPoint) / 100;
  if (normalizedFocalPoint === "left" || normalizedFocalPoint === "top")
    return 0;
  if (normalizedFocalPoint === "center") return 0.5;
  if (normalizedFocalPoint === "right" || normalizedFocalPoint === "bottom")
    return 1;
  console.warn("Invalid focal point coordinate, defaulting to center.");
  return 0.5;
}
const MILLISECONDS_IN_SECONDS = 1e3;
const DEG_TO_RAD = Math.PI / 180;
const prefersReducedMotion = window.matchMedia(
  "(prefers-reduced-motion)"
).matches;
const prefersReducedTransparency = window.matchMedia(
  "(prefers-reduced-transparency)"
).matches;
function isAndroid() {
  return /Android/i.test(navigator.userAgent);
}
function isIOS() {
  return /iPhone|iPad/i.test(navigator.userAgent);
}
function isMobile() {
  return isAndroid() || isIOS();
}
function randomIntInRange(min, max, inclusive = true) {
  return Math.floor(Math.random() * (max - min + (inclusive ? 1 : 0))) + min;
}
function randomFloatInRange(min, max) {
  return Math.random() * (max - min) + min;
}
function randomArrayIndex(array) {
  return randomIntInRange(
    0,
    array.length,
    /*inclusive*/
    false
  );
}
function randomArrayElement(array) {
  if (array.length === 0) throw new Error("Array is empty");
  const index = randomArrayIndex(array);
  return array[index];
}
function shuffleArray(array) {
  const shuffled_array = [...array];
  for (let i = shuffled_array.length; i > 1; i--) {
    const j = Math.floor(Math.random() * i);
    [shuffled_array[i - 1], shuffled_array[j]] = [
      shuffled_array[j],
      shuffled_array[i - 1]
    ];
  }
  return shuffled_array;
}
function loadImage(imageSrc) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error("Failed to load " + imageSrc));
    image.src = imageSrc;
  });
}
function imageSizeToFit(imageWidth, imageHeight, containerWidth, containerHeight) {
  const imageAspectRatio = imageWidth / imageHeight;
  const containerAspectRatio = containerWidth / containerHeight;
  let width, height;
  if (imageAspectRatio > containerAspectRatio) {
    height = containerHeight;
    width = imageAspectRatio * height;
  } else {
    width = containerWidth;
    height = width / imageAspectRatio;
  }
  return { imageSize: { width, height } };
}
function imageSizeToCover(imageWidth, imageHeight, containerWidth, containerHeight) {
  const imageAspectRatio = imageWidth / imageHeight;
  const containerAspectRatio = containerWidth / containerHeight;
  let width, height;
  if (imageAspectRatio > containerAspectRatio) {
    width = containerHeight;
    height = imageWidth * (containerHeight / imageHeight);
  } else {
    width = containerWidth;
    height = imageHeight * (containerWidth / imageWidth);
  }
  return { imageSize: { width, height } };
}
function hexToRgba(hex, alpha) {
  const [r, g, b] = _parseHexColor(hex);
  return `rgba(${r},${g},${b},${alpha})`;
}
function hexToRgb(hex) {
  const [r, g, b] = _parseHexColor(hex);
  return `rgb(${r},${g},${b})`;
}
function createCanvasWith2DContext(alpha = true) {
  const canvas = document.createElement("canvas");
  const canvasRenderingContext2D = canvas.getContext("2d", {
    alpha
  });
  return [canvas, canvasRenderingContext2D];
}
function clearCanvasRenderingContext2D(context) {
  context.clearRect(0, 0, context.canvas.width, context.canvas.height);
}
function parseFocalPoint(focalPoint) {
  const components = focalPoint.trim().split(/\s+/);
  if (components.length === 1) {
    const value = _parseFocalPointCoordinate(components[0]);
    return { x: value, y: value };
  }
  if (components.length === 2) {
    return {
      x: _parseFocalPointCoordinate(components[0]),
      y: _parseFocalPointCoordinate(components[1])
    };
  }
  console.warn("Invalid focal point, defaulting to center.");
  return { x: 0.5, y: 0.5 };
}
function parseDuration(duration) {
  const value = duration.trim().toLowerCase();
  if (value.endsWith("ms")) {
    return parseFloat(value);
  }
  if (value.endsWith("s")) {
    return parseFloat(value) * MILLISECONDS_IN_SECONDS;
  }
  return parseFloat(value);
}
const utils = {
  MILLISECONDS_IN_SECONDS,
  DEG_TO_RAD,
  prefersReducedMotion,
  prefersReducedTransparency,
  isAndroid,
  isIOS,
  isMobile,
  randomIntInRange,
  randomFloatInRange,
  randomArrayIndex,
  randomArrayElement,
  shuffleArray,
  loadImage,
  imageSizeToFit,
  imageSizeToCover,
  hexToRgba,
  hexToRgb,
  createCanvasWith2DContext,
  clearCanvasRenderingContext2D,
  parseFocalPoint,
  parseDuration
};
const dispatchedEvents = /* @__PURE__ */ new Set();
const RICH_MEDIA_EVENT = "richMediaEvent";
function _hasDispatchedEvent(eventType) {
  return dispatchedEvents.has(eventType);
}
function _targetOrigin() {
  return utils.isAndroid() ? "chrome://new-tab-takeover" : "chrome://newtab";
}
const eventTypes = {
  INTERACTION: "interaction",
  CLICK: "click"
};
function dispatchEvent(eventType) {
  if (_hasDispatchedEvent(eventType)) return;
  dispatchedEvents.add(eventType);
  window.parent.postMessage(
    { type: RICH_MEDIA_EVENT, value: eventType },
    _targetOrigin()
  );
}
const eventDispatcher = {
  eventTypes,
  dispatchEvent
};
function _bindClickToSelectors(object, handler) {
  const selectors = Array.isArray(object) ? object : [object];
  selectors.forEach((selector) => {
    const elements = document.querySelectorAll(selector);
    if (elements.length === 0) {
      console.warn(`No elements found for selector: ${selector}`);
      return;
    }
    elements.forEach(handler);
  });
}
function bindClickHandler(object, handler) {
  _bindClickToSelectors(
    object,
    (element) => element.addEventListener("click", handler)
  );
}
function bindAndDispatchClickEvent(object) {
  _bindClickToSelectors(
    object,
    (element) => element.addEventListener(
      "click",
      () => eventDispatcher.dispatchEvent(eventDispatcher.eventTypes.CLICK)
    )
  );
}
const eventBinder = {
  bindClickHandler,
  bindAndDispatchClickEvent
};
function initWallpaper() {
  eventBinder.bindAndDispatchClickEvent("img.wallpaper");
  function setFocalPoints() {
    const wallpaper = document.querySelector(".wallpaper");
    if (!wallpaper) {
      console.warn("Wallpaper not found, failed to initialize.");
      return;
    }
    wallpaper.style.objectPosition = wallpaper.getAttribute("data-focal-point") || "center";
  }
  setFocalPoints();
}
const MAX_FRAME_ELAPSED_SECONDS = 0.05;
const DIGITAL_RAIN_TRAIL = {
  // Font size for rain glyphs, in pixels.
  FONT_SIZE: 28,
  // Hex color of the glyphs.
  FONT_COLOR: "#e9eaea",
  // Hex color and alpha used for fading trails.
  FADE_COLOR: "#000",
  FADE_ALPHA: 0.2,
  // Horizontal spacing between columns, as a multiplier of font size.
  COLUMN_SPACING_FACTOR: 0.9,
  // Minimum and maximum number of glyphs per column.
  MIN_NUMBER_OF_GLYPHS: 6,
  MAX_NUMBER_OF_GLYPHS: 18,
  // Minimum and maximum time between glyph changes, in seconds.
  MIN_GLYPH_ANIMATION_SPEED: 0.35,
  MAX_GLYPH_ANIMATION_SPEED: 0.7,
  // Minimum and maximum vertical fall speed, in pixels per second (at devicePixelRatio = 1).
  MIN_FALL_SPEED: 70,
  MAX_FALL_SPEED: 160,
  // Alpha (opacity) for the trail's tail and head, 0.0 to 1.0.
  TAIL_ALPHA: 0,
  HEAD_ALPHA: 0.7
};
const BIOMETRIC_SWEEP_BAND = {
  // Hex color of the sweep band.
  COLOR: "#6b3af6",
  // Band opacity.
  OPACITY: 0.4,
  // Vertical height of the band in pixels.
  HEIGHT: 120,
  // Additional vertical distance in pixels the band travels beyond the canvas edge.
  MARGIN: 160,
  // Proportion of the band height used for gradient fade (0.0 to 1.0).
  GRADIENT_SPREAD: 0.66,
  // Type of animation for the biometric sweep band.
  ANIMATION_TYPE: 1,
  // Animation speed.
  ANIMATION_TIMING: {
    // Speed factor for the loop animation, 1.0 is normal speed.
    [
      0
      /* Loop */
    ]: 1,
    // Duration of a full oscillation in seconds.
    [
      1
      /* Oscillate */
    ]: 8
  }
};
const CAMERA_FLASH = {
  // Alpha (opacity) of the camera flash, 0.0 to 1.0.
  ALPHA_FACTOR: 0.7,
  // Speed at which the camera flash fades out, in seconds.
  FADE_SPEED: 2.5,
  // Hex color of the camera flash.
  COLOR: "#fff"
};
document.addEventListener("DOMContentLoaded", () => {
  initWallpaper();
  eventBinder.bindAndDispatchClickEvent(".button");
  const glyphs = "ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".split(
    ""
  );
  class DigitalRainEffect {
    effectLayer;
    effectLayerContext;
    offscreenEffectLayerCanvas;
    offscreenEffectLayerCanvasRenderingContext2D;
    effectLayerRect = { x: 0, y: 0, width: 0, height: 0 };
    biometricSweepMaskImage;
    offscreenBiometricSweepCanvas;
    offscreenBiometricSweepCanvasRenderingContext2D;
    offscreenDigitalRainCanvas;
    offscreenDigitalRainCanvasRenderingContext2D;
    digitalRainColumn = [];
    digitalRainFontSize;
    isCameraFlashActive = false;
    cameraFlashAlpha = 0;
    cameraFlashFadeSpeed = CAMERA_FLASH.FADE_SPEED;
    cameraFlashGuidesImage;
    lastBiometricSweepBandY = null;
    animationFrameId = null;
    lastFrameTime = performance.now();
    devicePixelRatio;
    constructor(effectLayerCanvas, effectLayerCanvasRenderingContext2D, biometricSweepMaskImage, cameraFlashGuidesImage) {
      this.effectLayer = effectLayerCanvas;
      this.effectLayerContext = effectLayerCanvasRenderingContext2D;
      this.biometricSweepMaskImage = biometricSweepMaskImage;
      this.cameraFlashGuidesImage = cameraFlashGuidesImage;
      [
        this.offscreenEffectLayerCanvas,
        this.offscreenEffectLayerCanvasRenderingContext2D
      ] = utils.createCanvasWith2DContext();
      [
        this.offscreenBiometricSweepCanvas,
        this.offscreenBiometricSweepCanvasRenderingContext2D
      ] = utils.createCanvasWith2DContext();
      [
        this.offscreenDigitalRainCanvas,
        this.offscreenDigitalRainCanvasRenderingContext2D
      ] = utils.createCanvasWith2DContext();
      this.devicePixelRatio = window.devicePixelRatio || 1;
      this.digitalRainFontSize = DIGITAL_RAIN_TRAIL.FONT_SIZE * this.devicePixelRatio;
    }
    init() {
      this.initEffectLayer();
      this.initDigitalRain();
      this.startAnimation();
    }
    initEffectLayer() {
      utils.clearCanvasRenderingContext2D(this.effectLayerContext);
      this.effectLayer.width = Math.floor(
        window.innerWidth * this.devicePixelRatio
      );
      this.offscreenEffectLayerCanvas.width = this.offscreenDigitalRainCanvas.width = this.offscreenBiometricSweepCanvas.width = this.effectLayer.width;
      this.effectLayer.height = Math.floor(
        window.innerHeight * this.devicePixelRatio
      );
      this.offscreenEffectLayerCanvas.height = this.offscreenDigitalRainCanvas.height = this.offscreenBiometricSweepCanvas.height = this.effectLayer.height;
      const wallpaper = document.querySelector(".wallpaper");
      const focalPoint = utils.parseFocalPoint(
        wallpaper?.dataset.focalPoint || "center"
      );
      this.effectLayerRect = this.computeEffectLayerRect(focalPoint);
    }
    initDigitalRain() {
      utils.clearCanvasRenderingContext2D(
        this.offscreenEffectLayerCanvasRenderingContext2D
      );
      this.offscreenEffectLayerCanvasRenderingContext2D.font = `${this.digitalRainFontSize}px monospace`;
      const columnWidth = this.digitalRainFontSize * DIGITAL_RAIN_TRAIL.COLUMN_SPACING_FACTOR;
      const columnCount = Math.ceil(
        this.offscreenEffectLayerCanvas.width / columnWidth
      );
      this.digitalRainColumn = Array.from(
        { length: columnCount },
        (_, index) => {
          const glyphTrailLength = utils.randomIntInRange(
            DIGITAL_RAIN_TRAIL.MIN_NUMBER_OF_GLYPHS,
            DIGITAL_RAIN_TRAIL.MAX_NUMBER_OF_GLYPHS
          );
          const columnGlyphs = Array.from({ length: glyphTrailLength }, () => ({
            char: utils.randomArrayElement(glyphs),
            delayInSeconds: utils.randomFloatInRange(
              DIGITAL_RAIN_TRAIL.MIN_GLYPH_ANIMATION_SPEED,
              DIGITAL_RAIN_TRAIL.MAX_GLYPH_ANIMATION_SPEED
            )
          }));
          return {
            x: index * columnWidth,
            y: utils.randomFloatInRange(
              -this.offscreenEffectLayerCanvas.height,
              0
            ),
            fallSpeed: utils.randomFloatInRange(
              DIGITAL_RAIN_TRAIL.MIN_FALL_SPEED,
              DIGITAL_RAIN_TRAIL.MAX_FALL_SPEED
            ) * this.devicePixelRatio,
            glyphTrailLength,
            glyphs: columnGlyphs
          };
        }
      );
    }
    // Effect layer.
    computeEffectLayerRect(focalPoint) {
      const scale = Math.max(
        this.offscreenDigitalRainCanvas.width / this.biometricSweepMaskImage.width,
        this.offscreenDigitalRainCanvas.height / this.biometricSweepMaskImage.height
      );
      const width = Math.ceil(this.biometricSweepMaskImage.width * scale);
      const x = Math.round(
        (this.offscreenDigitalRainCanvas.width - width) * focalPoint.x
      );
      const height = Math.ceil(this.biometricSweepMaskImage.height * scale);
      const y = Math.round(
        (this.offscreenDigitalRainCanvas.height - height) * focalPoint.y
      );
      return { x, y, width, height };
    }
    // Digital rain.
    updateDigitalRain(frameElapsedSeconds) {
      this.digitalRainColumn.forEach((column) => {
        column.y += column.fallSpeed * frameElapsedSeconds;
        if (column.y - column.glyphTrailLength * this.digitalRainFontSize > this.offscreenEffectLayerCanvas.height) {
          column.y = -utils.randomFloatInRange(
            0,
            this.offscreenEffectLayerCanvas.height * 0.5
          );
          column.fallSpeed = utils.randomFloatInRange(
            DIGITAL_RAIN_TRAIL.MIN_FALL_SPEED,
            DIGITAL_RAIN_TRAIL.MAX_FALL_SPEED
          ) * this.devicePixelRatio;
        }
        for (let index = 0; index < column.glyphTrailLength; index++) {
          const glyph = column.glyphs[index];
          glyph.delayInSeconds -= frameElapsedSeconds;
          if (glyph.delayInSeconds <= 0) {
            glyph.char = utils.randomArrayElement(glyphs);
            glyph.delayInSeconds = utils.randomFloatInRange(
              DIGITAL_RAIN_TRAIL.MIN_GLYPH_ANIMATION_SPEED,
              DIGITAL_RAIN_TRAIL.MAX_GLYPH_ANIMATION_SPEED
            );
          }
        }
      });
    }
    applyDigitalRainEffect() {
      this.offscreenEffectLayerCanvasRenderingContext2D.globalCompositeOperation = "destination-out";
      this.offscreenEffectLayerCanvasRenderingContext2D.fillStyle = utils.hexToRgba(
        DIGITAL_RAIN_TRAIL.FADE_COLOR,
        DIGITAL_RAIN_TRAIL.FADE_ALPHA
      );
      this.offscreenEffectLayerCanvasRenderingContext2D.fillRect(
        0,
        0,
        this.offscreenEffectLayerCanvas.width,
        this.offscreenEffectLayerCanvas.height
      );
      this.offscreenEffectLayerCanvasRenderingContext2D.globalCompositeOperation = "source-over";
    }
    drawDigitalRainColumns(context) {
      this.digitalRainColumn.forEach((column) => {
        for (let index = 0; index < column.glyphTrailLength; index++) {
          const glyph = column.glyphs[index];
          const y = column.y - index * this.digitalRainFontSize;
          const denominator = Math.max(1, column.glyphTrailLength - 1);
          const glyphTrailPosition = index / denominator;
          const alpha = DIGITAL_RAIN_TRAIL.HEAD_ALPHA * (1 - glyphTrailPosition) + DIGITAL_RAIN_TRAIL.TAIL_ALPHA * glyphTrailPosition;
          context.save();
          context.fillStyle = DIGITAL_RAIN_TRAIL.FONT_COLOR;
          context.globalAlpha = alpha;
          context.fillText(glyph.char, column.x, y);
          context.restore();
        }
      });
    }
    compositeDigitalRainWithMask() {
      utils.clearCanvasRenderingContext2D(
        this.offscreenDigitalRainCanvasRenderingContext2D
      );
      this.offscreenDigitalRainCanvasRenderingContext2D.drawImage(
        this.offscreenEffectLayerCanvas,
        0,
        0
      );
      this.offscreenDigitalRainCanvasRenderingContext2D.globalCompositeOperation = "destination-out";
      this.offscreenDigitalRainCanvasRenderingContext2D.drawImage(
        this.biometricSweepMaskImage,
        this.effectLayerRect.x,
        this.effectLayerRect.y,
        this.effectLayerRect.width,
        this.effectLayerRect.height
      );
      this.offscreenDigitalRainCanvasRenderingContext2D.globalCompositeOperation = "source-over";
    }
    renderDigitalRain() {
      this.applyDigitalRainEffect();
      this.drawDigitalRainColumns(
        this.offscreenEffectLayerCanvasRenderingContext2D
      );
      this.compositeDigitalRainWithMask();
      this.effectLayerContext.drawImage(this.offscreenDigitalRainCanvas, 0, 0);
    }
    // Biometric sweep band.
    computeBiometricSweepBandY(frameTime) {
      const gradientFadeHeight = BIOMETRIC_SWEEP_BAND.HEIGHT / 2;
      const verticalFieldOfView = this.offscreenEffectLayerCanvas.height + BIOMETRIC_SWEEP_BAND.HEIGHT + BIOMETRIC_SWEEP_BAND.MARGIN;
      switch (BIOMETRIC_SWEEP_BAND.ANIMATION_TYPE) {
        case 1:
          const amplitude = this.offscreenEffectLayerCanvas.height - BIOMETRIC_SWEEP_BAND.HEIGHT;
          const period = BIOMETRIC_SWEEP_BAND.ANIMATION_TIMING[
            1
            /* Oscillate */
          ] * utils.MILLISECONDS_IN_SECONDS;
          const normalizedTime = frameTime % period / period;
          return amplitude / 2 * (1 - Math.cos(normalizedTime * 2 * Math.PI)) - gradientFadeHeight;
        default:
        case 0:
          return frameTime * BIOMETRIC_SWEEP_BAND.ANIMATION_TIMING[
            0
            /* Loop */
          ] % verticalFieldOfView - gradientFadeHeight;
      }
    }
    createBiometricSweepBand(context, sweepBandCenterY, gradientFadeHeight) {
      const gradientSpreadHeight = gradientFadeHeight * BIOMETRIC_SWEEP_BAND.GRADIENT_SPREAD;
      const startY = sweepBandCenterY - gradientSpreadHeight;
      const endY = sweepBandCenterY + gradientSpreadHeight;
      const transparentColor = utils.hexToRgba(BIOMETRIC_SWEEP_BAND.COLOR, 0);
      const opaqueColor = utils.hexToRgba(
        BIOMETRIC_SWEEP_BAND.COLOR,
        BIOMETRIC_SWEEP_BAND.OPACITY
      );
      const gradient = context.createLinearGradient(0, startY, 0, endY);
      gradient.addColorStop(0, transparentColor);
      gradient.addColorStop(0.5, opaqueColor);
      gradient.addColorStop(1, transparentColor);
      return gradient;
    }
    drawBiometricSweepBand(context, frameTime) {
      const gradientFadeHeight = BIOMETRIC_SWEEP_BAND.HEIGHT / 2;
      const bandY = this.computeBiometricSweepBandY(frameTime);
      const band = this.createBiometricSweepBand(
        context,
        bandY,
        gradientFadeHeight
      );
      context.save();
      context.fillStyle = band;
      context.fillRect(
        0,
        bandY - gradientFadeHeight,
        this.offscreenEffectLayerCanvas.width,
        BIOMETRIC_SWEEP_BAND.HEIGHT
      );
      context.restore();
    }
    compositeBiometricSweepBandWithMask(context) {
      context.globalCompositeOperation = "destination-in";
      context.drawImage(
        this.biometricSweepMaskImage,
        this.effectLayerRect.x,
        this.effectLayerRect.y,
        this.effectLayerRect.width,
        this.effectLayerRect.height
      );
      context.globalCompositeOperation = "source-over";
    }
    renderBiometricSweepBand(frameTime) {
      utils.clearCanvasRenderingContext2D(
        this.offscreenBiometricSweepCanvasRenderingContext2D
      );
      this.drawBiometricSweepBand(
        this.offscreenBiometricSweepCanvasRenderingContext2D,
        frameTime
      );
      this.compositeBiometricSweepBandWithMask(
        this.offscreenBiometricSweepCanvasRenderingContext2D
      );
      this.effectLayerContext.drawImage(
        this.offscreenBiometricSweepCanvas,
        0,
        0
      );
    }
    // Camera flash.
    updateCameraFlash(frameElapsedSeconds) {
      if (!this.isCameraFlashActive && this.cameraFlashAlpha <= 0) return;
      this.maybeFadeOutCameraFlash(frameElapsedSeconds);
    }
    maybeTriggerCameraFlash(frameTime) {
      const biometricSweepBandY = this.computeBiometricSweepBandY(frameTime);
      const halfway = this.offscreenEffectLayerCanvas.height / 2;
      if (this.lastBiometricSweepBandY && this.lastBiometricSweepBandY < halfway && biometricSweepBandY >= halfway) {
        this.triggerCameraFlash();
      }
      this.lastBiometricSweepBandY = biometricSweepBandY;
    }
    triggerCameraFlash() {
      this.cameraFlashAlpha = 1;
      this.isCameraFlashActive = true;
    }
    maybeFadeOutCameraFlash(frameElapsedSeconds) {
      if (!this.isCameraFlashActive) return;
      this.cameraFlashAlpha -= this.cameraFlashFadeSpeed * frameElapsedSeconds;
      if (this.cameraFlashAlpha > 0) {
        return;
      }
      this.cameraFlashAlpha = 0;
      this.isCameraFlashActive = false;
    }
    maybeDrawCameraFlash() {
      if (this.cameraFlashAlpha <= 0) return;
      this.effectLayerContext.save();
      this.effectLayerContext.globalAlpha = this.cameraFlashAlpha * CAMERA_FLASH.ALPHA_FACTOR;
      this.effectLayerContext.fillStyle = CAMERA_FLASH.COLOR;
      this.effectLayerContext.fillRect(
        0,
        0,
        this.effectLayer.width,
        this.effectLayer.height
      );
      this.effectLayerContext.restore();
    }
    maybeDrawCameraFlashGuides() {
      if (!this.cameraFlashGuidesImage || this.cameraFlashAlpha <= 0) return;
      this.effectLayerContext.save();
      this.effectLayerContext.globalAlpha = Math.max(this.cameraFlashAlpha, 1);
      this.effectLayerContext.drawImage(
        this.cameraFlashGuidesImage,
        this.effectLayerRect.x,
        this.effectLayerRect.y,
        this.effectLayerRect.width,
        this.effectLayerRect.height
      );
      this.effectLayerContext.restore();
    }
    // Animation.
    frame = (frameTime) => {
      const frameElapsedSeconds = Math.min(
        MAX_FRAME_ELAPSED_SECONDS,
        (frameTime - this.lastFrameTime) / utils.MILLISECONDS_IN_SECONDS
      );
      this.lastFrameTime = frameTime;
      utils.clearCanvasRenderingContext2D(this.effectLayerContext);
      this.renderBiometricSweepBand(frameTime);
      this.updateDigitalRain(frameElapsedSeconds);
      this.renderDigitalRain();
      this.maybeTriggerCameraFlash(frameTime);
      this.updateCameraFlash(frameElapsedSeconds);
      this.maybeDrawCameraFlash();
      this.maybeDrawCameraFlashGuides();
      this.animationFrameId = requestAnimationFrame(this.frame);
    };
    startAnimation() {
      this.maybeCancelAnimation();
      requestAnimationFrame((frameTime) => {
        this.lastFrameTime = frameTime;
        this.frame(frameTime);
      });
    }
    maybeCancelAnimation() {
      if (this.animationFrameId !== null) {
        cancelAnimationFrame(this.animationFrameId);
        this.animationFrameId = null;
      }
    }
  }
  (async () => {
    if (utils.prefersReducedMotion) {
      console.warn("User prefers reduced motion. Skipping animations.");
      return;
    }
    const effectLayer = document.getElementById(
      "effect-layer"
    );
    if (!effectLayer) {
      console.error("Failed to get effect layer element");
      return;
    }
    const effectLayerContext = effectLayer.getContext("2d", {
      alpha: true
    });
    if (!effectLayerContext) {
      console.error("Failed to get 2D context from effect layer");
      return;
    }
    let biometricSweepMaskImage;
    try {
      biometricSweepMaskImage = await utils.loadImage(
        "biometric-sweep-mask.png"
      );
    } catch (error) {
      console.error("Failed to load biometric sweep mask image: ", error);
      return;
    }
    let cameraFlashGuidesImage;
    try {
      cameraFlashGuidesImage = await utils.loadImage("camera-flash-guides.png");
    } catch (error) {
      console.error("Failed to load camera flash guides image: ", error);
      return;
    }
    const effect = new DigitalRainEffect(
      effectLayer,
      effectLayerContext,
      biometricSweepMaskImage,
      cameraFlashGuidesImage
    );
    effect.init();
    window.addEventListener("resize", () => effect.init(), { passive: true });
  })();
});
