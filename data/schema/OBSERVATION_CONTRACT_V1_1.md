# Green Deals BR — Observation Contract V1.1

## Objetivo

Permitir que o Green Deals registre observacoes comerciais mesmo quando nenhum preco estiver disponivel.

O Contract V1.1 e retrocompativel com o Contract V1.0.

## Tipos de observacao

### priced_offer

Usado quando existe uma oferta comercial com preco verificavel.

Exige:

- preco;
- vendedor;
- disponibilidade;
- moeda;
- data da observacao;
- marketplace;
- offer_id;
- fonte.

### availability_only

Usado quando o produto ou anuncio existe, mas naquele momento nao ha preco/oferta comercial valida.

Exemplos:

- sem_oferta_destacada;
- fora_de_estoque;
- indisponivel.

Nesse tipo de evento:

- commercial.price deve ser omitido;
- commercial.seller pode ser omitido;
- a ausencia de preco e um dado valido;
- nenhum preco deve ser inventado ou reaproveitado como se fosse atual.

## Regra de historico

O ultimo preco valido conhecido continua preservado no historico.

Um evento sem preco nao deve apagar o historico anterior.

## Opportunity Engine

O Opportunity Engine continuara calculando estatisticas somente com snapshots que contenham preco.

Eventos sem preco deverao futuramente informar tambem o estado comercial atual da oferta.

## Principio central

A ausencia de oferta e informacao.

O Green Deals deve registrar indisponibilidade em vez de inventar um preco para preencher campos.
