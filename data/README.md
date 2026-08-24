# Green Deals BR — Estrutura de dados de ofertas

Este diretório contém a camada estruturada de dados comerciais do Green Deals BR.

## Objetivo

Separar os dados dos produtos da apresentação visual do site.

Hoje o cadastro pode ser feito manualmente.
No futuro, o Hermes deverá coletar, validar, atualizar e publicar estes dados automaticamente.

Fluxo planejado:

marketplace
→ coleta
→ validação
→ análise
→ banco de dados
→ publicação
→ rastreamento
→ atualização

## Arquivo principal

`ofertas.json`

## Estrutura de cada oferta

Cada oferta deve possuir:

- ID interno GDBR
- status operacional
- status editorial
- marketplace
- identificador do programa de afiliados
- identificador do produto no marketplace
- categoria e subcategoria
- especificações técnicas
- preço observado
- data de verificação
- vendedor
- disponibilidade
- URL original
- URL afiliada
- imagem
- avaliação editorial
- dados ainda ausentes
- informações de rastreamento

## Estados editoriais sugeridos

- `em_analise`
- `aprovado`
- `recomendado`
- `necessita_comparacao`
- `reprovado`

## Estados operacionais sugeridos

- `active`
- `out_of_stock`
- `price_changed`
- `unavailable`
- `archived`

## Regra importante

Preço, disponibilidade, vendedor, imagem e condições comerciais são dados mutáveis.

O Hermes deverá verificá-los periodicamente antes de manter uma oferta publicada.

O HTML não deve ser considerado a fonte definitiva dos dados.

A fonte definitiva deverá ser esta camada de dados ou, futuramente, o banco central do Hermes.
