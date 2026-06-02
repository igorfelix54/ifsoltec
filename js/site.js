document.addEventListener("DOMContentLoaded", () => {
  const toggle = document.querySelector(".menu-toggle");
  const menu = document.getElementById("mainMenu");

  if (!toggle || !menu) {
    return;
  }

  function setMenuOpen(isOpen) {
    document.body.classList.toggle("menu-open", isOpen);
    menu.classList.toggle("open", isOpen);
    toggle.setAttribute("aria-expanded", String(isOpen));

    const icon = toggle.querySelector("i");

    if (icon) {
      icon.classList.toggle("fa-bars", !isOpen);
      icon.classList.toggle("fa-xmark", isOpen);
    }
  }

  toggle.addEventListener("click", () => {
    setMenuOpen(!menu.classList.contains("open"));
  });

  menu.querySelectorAll("a").forEach(link => {
    link.addEventListener("click", () => {
      setMenuOpen(false);
    });
  });

  window.addEventListener("resize", () => {
    if (window.matchMedia("(min-width: 769px)").matches) {
      setMenuOpen(false);
    }
  });

  document.addEventListener("keydown", event => {
    if (event.key === "Escape") {
      setMenuOpen(false);
    }
  });
});
