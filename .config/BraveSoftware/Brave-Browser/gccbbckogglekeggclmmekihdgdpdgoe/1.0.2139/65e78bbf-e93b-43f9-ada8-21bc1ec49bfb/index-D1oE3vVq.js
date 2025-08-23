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
function initCarousel() {
  const isScrollEndEventSupported = "onscrollend" in document.createElement("div");
  const maybeCarousel = document.querySelector(".carousel");
  if (!maybeCarousel) return;
  const carousel = maybeCarousel;
  if (!carousel.hasAttribute("data-animation-style")) {
    carousel.setAttribute("data-animation-style", "scroll");
  }
  const animationStyle = carousel.getAttribute("data-animation-style");
  const slides = document.querySelectorAll(".carousel-slide");
  if (!slides) return;
  let currentSlide = 0;
  const slideDisplayOrder = shuffleSlideDisplayOrder(
    carousel,
    slides
  );
  let autoplayInterval = null;
  let isFirstRun = true;
  setSlideFocalPoints();
  displaySlide(currentSlide);
  addEventListeners();
  maybeCreatePaginationDots();
  maybeUpdatePaginationDots(currentSlide);
  maybeStartAutoplay();
  function shuffleSlideDisplayOrder(carousel2, slides2) {
    let slideDisplayOrder2 = Array.from(slides2, (_, i) => i);
    const displayOrder = carousel2.getAttribute("data-display-order") || "sequential";
    if (displayOrder === "shuffle") {
      slideDisplayOrder2 = utils.shuffleArray(slideDisplayOrder2);
      const slidesArray = Array.from(slides2);
      slideDisplayOrder2.forEach((index) => {
        carousel2.appendChild(slidesArray[index]);
      });
    }
    return slideDisplayOrder2;
  }
  function setSlideFocalPoints() {
    document.querySelectorAll(".carousel-slide img").forEach((img) => {
      img.style.objectPosition = img.getAttribute("data-focal-point") || "center";
    });
  }
  function displaySlide(index) {
    if (index < 0 || index >= slides.length) return;
    const slideIndex = slideDisplayOrder[index];
    if (utils.prefersReducedMotion) {
      carousel.scrollTo({
        left: index * carousel.clientWidth,
        behavior: "auto"
      });
      return;
    }
    if (animationStyle === "fade") {
      slides.forEach((slide, i) => {
        if (!isFirstRun) {
          slide.style.transition = "opacity 1s ease";
        }
        slide.classList.toggle("active", i === slideIndex);
      });
      isFirstRun = false;
    } else if (animationStyle === "scroll") {
      carousel.scrollTo({
        left: index * carousel.clientWidth,
        behavior: "smooth"
      });
    }
  }
  function nextSlide() {
    resetAutoplay();
    currentSlide = (currentSlide + 1) % slides.length;
    maybeUpdatePaginationDots(currentSlide);
    displaySlide(currentSlide);
  }
  function nextSlideWithUserInteraction() {
    nextSlide();
    eventDispatcher.dispatchEvent(eventDispatcher.eventTypes.INTERACTION);
  }
  function prevSlide() {
    resetAutoplay();
    currentSlide = (currentSlide - 1 + slides.length) % slides.length;
    maybeUpdatePaginationDots(currentSlide);
    displaySlide(currentSlide);
  }
  function prevSlideWithUserInteraction() {
    prevSlide();
    eventDispatcher.dispatchEvent(eventDispatcher.eventTypes.INTERACTION);
  }
  function maybeCreatePaginationDots() {
    const paginationDots = document.querySelector(".carousel-pagination-dots");
    if (!paginationDots) return;
    slides.forEach((_, i) => {
      const pagination_dot = document.createElement("span");
      pagination_dot.classList.add("carousel-pagination-dot");
      pagination_dot.addEventListener("click", () => {
        resetAutoplay();
        currentSlide = i;
        maybeUpdatePaginationDots(currentSlide);
        displaySlide(currentSlide);
        eventDispatcher.dispatchEvent(eventDispatcher.eventTypes.INTERACTION);
      });
      paginationDots.appendChild(pagination_dot);
    });
  }
  function maybeUpdatePaginationDots(index) {
    if (index < 0 || index >= slides.length) return;
    document.querySelectorAll(".carousel-pagination-dot").forEach((paginationDot, i) => {
      paginationDot.classList.toggle("active", i === index);
    });
  }
  function addEventListeners() {
    document.addEventListener("visibilitychange", handleVisibilityChange);
    carousel.addEventListener("scroll", handleScroll);
    carousel.addEventListener("scrollend", handleScrollEnd);
    eventBinder.bindAndDispatchClickEvent(".carousel-slide img");
    eventBinder.bindClickHandler(
      ".carousel-navigation.next",
      nextSlideWithUserInteraction
    );
    eventBinder.bindClickHandler(
      ".carousel-navigation.prev",
      prevSlideWithUserInteraction
    );
  }
  function calculateAutoplayInterval() {
    const autoplay = carousel.getAttribute("data-autoplay");
    if (!autoplay) {
      return document.querySelector(".carousel-navigation-container") ? 0 : 3;
    }
    return Number(autoplay);
  }
  function maybeStartAutoplay() {
    const intervalInSeconds = calculateAutoplayInterval();
    if (intervalInSeconds > 0) {
      startAutoplay(intervalInSeconds);
    }
  }
  function startAutoplay(intervalInSeconds) {
    stopAutoplay();
    autoplayInterval = window.setInterval(
      nextSlide,
      intervalInSeconds * utils.MILLISECONDS_IN_SECONDS
    );
  }
  function stopAutoplay() {
    if (autoplayInterval) {
      clearInterval(autoplayInterval);
      autoplayInterval = null;
    }
  }
  function resetAutoplay() {
    stopAutoplay();
    maybeStartAutoplay();
  }
  function handleVisibilityChange() {
    document.visibilityState === "visible" ? maybeStartAutoplay() : stopAutoplay();
  }
  function handleScroll() {
    if (animationStyle !== "scroll") return;
    resetAutoplay();
    currentSlide = Math.round(carousel.scrollLeft / carousel.clientWidth);
    if (!isScrollEndEventSupported) {
      handleScrollEnd();
    }
  }
  function handleScrollEnd() {
    if (animationStyle !== "scroll") return;
    maybeUpdatePaginationDots(currentSlide);
  }
}
function layoutNavigationContainer() {
  const navigationContainer = document.querySelector(
    ".carousel-navigation-container"
  );
  if (!navigationContainer) {
    return;
  }
  navigationContainer.style.bottom = "50px";
}
function layoutMobile() {
  if (!utils.isMobile()) {
    return;
  }
  layoutNavigationContainer();
}
document.addEventListener("DOMContentLoaded", () => {
  initCarousel();
  eventBinder.bindAndDispatchClickEvent(".brand-button");
  layoutMobile();
});
