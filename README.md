# IFSOLTEC

Site institucional e loja estática da IFSOLTEC.

## Estrutura

- `index.html`: página institucional com serviços, sobre, projetos e contato.
- `loja.html`: catálogo de produtos.
- `produtos.json`: base de produtos usada pela loja.
- `css/`: estilos das páginas.
- `js/`: scripts de navegação, filtro, ordenação e renderização do catálogo.
- `produtos/`: imagens dos produtos.

## Como rodar localmente

Como a loja carrega `produtos.json` com `fetch`, abra o projeto por um servidor local:

```powershell
npx serve .
```

Ou, sem instalar pacotes:

```powershell
node dev-server.js
```

Depois acesse `http://localhost:8000`.

## Validar o catálogo

```powershell
node validate-catalog.js
```

O script verifica se o JSON é válido, se os produtos têm campos essenciais, se há IDs duplicados e se as imagens apontadas existem.

## Checklist antes de publicar

- Verificar `node validate-catalog.js`.
- Conferir `index.html` e `loja.html` no celular.
- Confirmar se `banner.png` está publicado na raiz do domínio.
- Manter imagens de ícone pequenas, preferindo `icon2.png` para favicon.
