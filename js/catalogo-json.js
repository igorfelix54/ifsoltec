/**
 * Catálogo carregado a partir de produtos.json
 * Coloque este arquivo e produtos.json no mesmo diretório da página HTML.
 */
document.addEventListener("DOMContentLoaded", carregarProdutos);

async function carregarProdutos() {
  const grade = document.getElementById("productsGrid");

  if (!grade) {
    console.error('Elemento com id="productsGrid" não encontrado.');
    return;
  }

  try {
    const resposta = await fetch("./produtos.json", { cache: "no-store" });

    if (!resposta.ok) {
      throw new Error(`Não foi possível carregar produtos.json: HTTP ${resposta.status}`);
    }

    const produtos = await resposta.json();

    if (!Array.isArray(produtos)) {
      throw new Error("O conteúdo de produtos.json precisa ser uma lista de produtos.");
    }

    grade.innerHTML = produtos.map(criarCardProduto).join("");
    ativarGalerias(grade);
    ativarBotoesDetalhes(grade);

    // Permite que outros scripts do site atualizem filtros, contadores ou ordenação.
    document.dispatchEvent(
      new CustomEvent("productsRendered", { detail: { produtos } })
    );
  } catch (erro) {
    console.error(erro);
    grade.innerHTML = `
      <p class="products-error">
        Não foi possível carregar os produtos. Verifique se o arquivo
        <strong>produtos.json</strong> está no diretório correto e execute o site
        por um servidor local ou pela hospedagem.
      </p>
    `;
  }
}

function criarCardProduto(produto) {
  const imagens = Array.isArray(produto.images) ? produto.images.filter(Boolean) : [];
  const imagemPrincipal = imagens[0] || "produtos/sem-imagem.webp";
  const detalhes = Array.isArray(produto.details) ? produto.details : [];

  return `
    <div class="product-card"
         data-product-id="${escapar(produto.id || "")}"
         data-name="${escapar(produto.name || produto.title || "")}"
         data-category="${escapar(produto.category || "")}"
         data-price="${Number(produto.price) || 0}">

      <div class="product-gallery">
        <img class="main-image"
             src="${escapar(imagemPrincipal)}"
             alt="${escapar(produto.title || produto.name || "Produto")}"
             loading="lazy">

        <div class="thumbs">
          ${imagens.map((imagem, indice) => `
            <img src="${escapar(imagem)}"
                 alt="${escapar(produto.title || produto.name || "Produto")} - imagem ${indice + 1}"
                 loading="lazy">
          `).join("")}
        </div>
      </div>

      <div class="product-content">
        <h3>${escapar(produto.title || produto.name || "")}</h3>

        <p class="product-description">
          ${escapar(produto.description || "")}
        </p>

        <div class="product-info">
          <div class="price">${formatarPreco(produto.price)}</div>
          <div class="badge">${escapar(produto.badge || "Novo")}</div>
        </div>

        <button class="details-btn"
                type="button"
                aria-expanded="false">
          Ver detalhes
        </button>

        <div class="product-details" hidden>
          <ul>
            ${detalhes.map(item => `<li>${escapar(item)}</li>`).join("")}
          </ul>
        </div>

        <a href="${escapar(produto.whatsapp || "https://wa.me/5591993015536")}"
           target="_blank"
           rel="noopener noreferrer"
           class="btn-whatsapp">
          <i class="fab fa-whatsapp"></i>
          Comprar via WhatsApp
        </a>
      </div>
    </div>
  `;
}

function ativarGalerias(grade) {
  grade.querySelectorAll(".product-gallery").forEach(galeria => {
    const imagemPrincipal = galeria.querySelector(".main-image");

    galeria.querySelectorAll(".thumbs img").forEach(miniatura => {
      miniatura.addEventListener("click", () => {
        if (imagemPrincipal) {
          imagemPrincipal.src = miniatura.src;
          imagemPrincipal.alt = miniatura.alt;
        }
      });
    });
  });
}

function ativarBotoesDetalhes(grade) {
  // Usa delegação de eventos para funcionar também com cards criados pelo JSON.
  // A classe "active" e o style.display garantem compatibilidade com o CSS antigo.
  if (grade.dataset.detailsListenerAtivo === "true") {
    return;
  }

  grade.dataset.detailsListenerAtivo = "true";

  grade.addEventListener("click", evento => {
    const botao = evento.target.closest(".details-btn");

    if (!botao || !grade.contains(botao)) {
      return;
    }

    const card = botao.closest(".product-card");
    const detalhes = card?.querySelector(".product-details");

    if (!detalhes) {
      return;
    }

    const estaAberto =
      detalhes.classList.contains("active") ||
      detalhes.classList.contains("show") ||
      detalhes.style.display === "block" ||
      !detalhes.hidden;

    detalhes.hidden = estaAberto;
    detalhes.style.display = estaAberto ? "none" : "block";
    detalhes.classList.toggle("active", !estaAberto);
    detalhes.classList.toggle("show", !estaAberto);
    detalhes.classList.toggle("open", !estaAberto);

    botao.setAttribute("aria-expanded", String(!estaAberto));
    botao.textContent = estaAberto ? "Ver detalhes" : "Ocultar detalhes";
  });
}

function formatarPreco(valor) {
  return Number(valor || 0).toLocaleString("pt-BR", {
    style: "currency",
    currency: "BRL"
  });
}

function escapar(valor) {
  return String(valor ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
