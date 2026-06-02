/*========================================
  FILTRO, PESQUISA E ORDENAÇÃO DE PRODUTOS
  Compatível com catálogo JSON e submenus flutuantes.
==========================================*/

document.addEventListener("DOMContentLoaded", () => {
  const searchInput = document.getElementById("searchInput");
  const sortSelect = document.getElementById("sortSelect");
  const productsGrid = document.getElementById("productsGrid");
  const categoriesContainer = document.querySelector(".categories");
  const categoryButtons = document.querySelectorAll(".category");
  const groupButtons = document.querySelectorAll(".category-group-btn");
  const subcategoryMenus = document.querySelectorAll(".subcategory-menu");

  let currentCategory = "all";
  let emptyState = null;

  if (!productsGrid) {
    console.error('Elemento com id="productsGrid" não encontrado.');
    return;
  }

  const selectedCategoryIndicator = document.createElement("div");
  selectedCategoryIndicator.id = "selectedCategoryIndicator";
  selectedCategoryIndicator.className = "selected-category-indicator";
  selectedCategoryIndicator.innerHTML = `
    <i class="fas fa-filter"></i>
    <span>Categoria selecionada: <strong>Todos</strong></span>
  `;

  categoriesContainer?.insertAdjacentElement(
    "afterend",
    selectedCategoryIndicator
  );

  function getEmptyState() {
    if (emptyState) {
      return emptyState;
    }

    emptyState = document.createElement("p");
    emptyState.className = "products-empty";
    emptyState.textContent = "Nenhum produto encontrado com esses filtros.";
    emptyState.hidden = true;

    productsGrid.insertAdjacentElement("afterend", emptyState);

    return emptyState;
  }

  function getProducts() {
    return Array.from(
      productsGrid.querySelectorAll(".product-card")
    );
  }

  function normalizeText(value) {
    return String(value || "")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .trim();
  }

  function getButtonLabel(button) {
    return String(button?.textContent || "")
      .replace(/\s+/g, " ")
      .trim();
  }

  function updateSelectedCategory(label) {
    const strong = selectedCategoryIndicator.querySelector("strong");

    if (strong) {
      strong.textContent = label || "Todos";
    }
  }

  function closeAllMenus() {
    subcategoryMenus.forEach(menu => {
      menu.hidden = true;
    });

    groupButtons.forEach(button => {
      button.classList.remove("active");
    });
  }

  function filterProducts() {
    const searchText = normalizeText(searchInput?.value);
    const products = getProducts();
    let visibleCount = 0;

    products.forEach(product => {
      const productSearch = normalizeText(
        product.dataset.search || product.dataset.name
      );

      const productCategory = String(
        product.dataset.category || ""
      ).trim().toLowerCase();

      const matchesSearch =
        !searchText || productSearch.includes(searchText);

      const matchesCategory =
        currentCategory === "all" ||
        productCategory === currentCategory;

      const isVisible = matchesSearch && matchesCategory;

      product.style.display = isVisible ? "" : "none";

      if (isVisible) {
        visibleCount += 1;
      }
    });

    getEmptyState().hidden = visibleCount > 0;
  }

  function sortProducts() {
    const products = getProducts();
    const value = sortSelect?.value || "random";

    if (value === "az") {
      products.sort((a, b) =>
        String(a.dataset.name || "").localeCompare(
          String(b.dataset.name || ""),
          "pt-BR"
        )
      );
    }

    if (value === "price-low") {
      products.sort(
        (a, b) =>
          Number(a.dataset.price || 0) -
          Number(b.dataset.price || 0)
      );
    }

    if (value === "price-high") {
      products.sort(
        (a, b) =>
          Number(b.dataset.price || 0) -
          Number(a.dataset.price || 0)
      );
    }

    if (value === "random") {
      products.sort(() => Math.random() - 0.5);
    }

    products.forEach(product => {
      productsGrid.appendChild(product);
    });

    filterProducts();
  }

  groupButtons.forEach(button => {
    button.addEventListener("click", event => {
      event.stopPropagation();

      const target = String(
        button.dataset.groupTarget || ""
      ).trim().toLowerCase();

      const menu = document.querySelector(
        `[data-group-panel="${target}"]`
      );

      const wasOpen = menu && !menu.hidden;

      closeAllMenus();

      if (menu && !wasOpen) {
        menu.hidden = false;
        button.classList.add("active");
      }
    });
  });

  categoryButtons.forEach(button => {
    button.addEventListener("click", event => {
      event.stopPropagation();

      currentCategory = String(
        button.dataset.filter || "all"
      ).trim().toLowerCase();

      categoryButtons.forEach(item => {
        item.classList.remove("active");
      });

      button.classList.add("active");

      if (currentCategory === "all") {
        updateSelectedCategory("Todos");
      } else {
        const menu = button.closest(".subcategory-menu");
        const groupButton = menu
          ? document.querySelector(
              `[data-group-target="${menu.dataset.groupPanel}"]`
            )
          : null;

        const groupLabel = getButtonLabel(groupButton);
        const categoryLabel = getButtonLabel(button);

        updateSelectedCategory(
          groupLabel
            ? `${groupLabel} > ${categoryLabel}`
            : categoryLabel
        );
      }

      closeAllMenus();
      filterProducts();
    });
  });

  document.addEventListener("click", event => {
    if (!event.target.closest(".category-dropdown")) {
      closeAllMenus();
    }
  });

  document.addEventListener("keydown", event => {
    if (event.key === "Escape") {
      closeAllMenus();
    }
  });

  searchInput?.addEventListener("input", filterProducts);

  sortSelect?.addEventListener("change", sortProducts);

  document.addEventListener("productsRendered", () => {
    sortProducts();
  });

  window.addEventListener("load", () => {
    sortProducts();
  });
});
