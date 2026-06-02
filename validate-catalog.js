const fs = require("fs");
const path = require("path");

const catalogPath = path.join(__dirname, "produtos.json");
const requiredFields = ["id", "title", "category", "price", "images"];
const issues = [];

function addIssue(message) {
  issues.push(message);
}

function fileExists(relativePath) {
  return fs.existsSync(path.join(__dirname, relativePath));
}

let products;

try {
  products = JSON.parse(fs.readFileSync(catalogPath, "utf8"));
} catch (error) {
  console.error(`Erro ao ler produtos.json: ${error.message}`);
  process.exit(1);
}

if (!Array.isArray(products)) {
  console.error("produtos.json precisa conter uma lista de produtos.");
  process.exit(1);
}

const seenIds = new Set();

products.forEach((product, index) => {
  const label = product.id || `produto na posição ${index + 1}`;

  requiredFields.forEach(field => {
    const value = product[field];
    const isMissingArray = Array.isArray(value) && value.length === 0;

    if (value === undefined || value === null || value === "" || isMissingArray) {
      addIssue(`${label}: campo obrigatório ausente ou vazio: ${field}`);
    }
  });

  if (seenIds.has(product.id)) {
    addIssue(`${label}: id duplicado`);
  }

  seenIds.add(product.id);

  if (Number.isNaN(Number(product.price))) {
    addIssue(`${label}: preço inválido`);
  }

  if (Array.isArray(product.images)) {
    product.images.forEach(imagePath => {
      if (!fileExists(imagePath)) {
        addIssue(`${label}: imagem não encontrada: ${imagePath}`);
      }
    });
  }
});

if (issues.length > 0) {
  console.error(`Catálogo com ${issues.length} problema(s):`);
  issues.forEach(issue => console.error(`- ${issue}`));
  process.exit(1);
}

console.log(`Catálogo OK: ${products.length} produto(s) validados.`);
