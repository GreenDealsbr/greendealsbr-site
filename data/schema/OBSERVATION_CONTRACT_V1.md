# Green Deals BR — Observation Contract V1

## Objetivo

Padronizar a entrada de observacoes comerciais recebidas de marketplaces, coletores e futuros agentes do Hermes.

O contrato funciona como fronteira entre coleta externa e infraestrutura interna.

Fluxo:

marketplace → coletor → Observation Contract → Snapshot Collector → histórico → Opportunity Engine.

## Campos obrigatórios

- contract_version
- offer_id
- marketplace
- observed_at
- source
- commercial.currency
- commercial.price
- commercial.availability
- commercial.seller

## Campos opcionais

- product_id
- product_title
- price_from
- discount_percent
- seller_type
- parcelamento
- rating
- reviews
- sold_quantity
- product_url
- affiliate_url
- metadados de proveniência

## Regra editorial e comercial

Campos opcionais sem evidência devem ser omitidos.

Nunca inventar preço anterior, desconto, avaliação, volume vendido, benefício, comissão ou qualquer outra informação para completar o objeto.

Um desconto informado pelo marketplace é apenas uma observação comercial.

Ele não representa validação de oportunidade pelo Green Deals.

Essa validação pertence ao Opportunity Engine.

## Compatibilidade

O mesmo contrato deverá ser usado por Amazon, Mercado Livre, Shopee e futuros marketplaces.

Cada conector pode coletar dados de maneira diferente, mas deve normalizá-los para este formato antes de entregá-los à infraestrutura GDBR.

## Segurança

O Snapshot Collector continua em dry-run por padrão.

Uma observação válida não implica escrita automática na base.

A escrita real continua exigindo confirmação explícita via --apply.
