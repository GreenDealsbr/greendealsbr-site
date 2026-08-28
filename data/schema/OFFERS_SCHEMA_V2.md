# Green Deals BR — Offers Schema V2

## Objetivo

Preparar a camada comercial do Green Deals BR para automação futura pelo Hermes.

O modelo separa o estado atual do histórico temporal.

## Estado atual

Arquivo: `data/ofertas.json`

Representa a melhor informação conhecida no momento sobre cada oferta.

Inclui preço atual, vendedor, disponibilidade, condições comerciais, URL afiliada, avaliação editorial, especificações e estado operacional.

## Histórico

Diretório: `data/history/`

Cada oferta possui um arquivo próprio no formato `GDBR-OFFER-XXX.jsonl`.

O histórico é append-only.

Cada nova observação cria uma nova linha. Registros anteriores nunca devem ser sobrescritos.

## Hermes

O fluxo futuro será:

descobrir produto → coletar → validar → registrar snapshot → comparar com histórico → calcular oportunidade → atualizar estado atual → decidir publicação → validar link afiliado → publicar → monitorar.

## Regra fundamental

Nunca considerar apenas o texto promocional do marketplace.

Uma promoção real deverá considerar, quando houver histórico suficiente:

- preço atual;
- preço anterior observado;
- média histórica;
- menor preço observado;
- disponibilidade;
- vendedor;
- condições comerciais;
- especificações;
- confiabilidade da informação.

## Fonte definitiva

O HTML não é fonte definitiva dos dados.

`data/ofertas.json` representa o estado atual.

`data/history/` representa a memória temporal.

Futuramente ambos poderão migrar para banco de dados preservando o mesmo modelo conceitual.
