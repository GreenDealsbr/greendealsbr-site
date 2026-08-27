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


## Padrão global dos cards de oferta

Todos os marketplaces devem usar o mesmo componente visual e estrutural de preço.

Ordem preferencial:

1. resumo do produto;
2. preço anterior, quando houver dado real;
3. preço atual;
4. percentual de desconto, quando verificável;
5. condição de pagamento;
6. parcelamento;
7. observação/data da coleta;
8. CTA para o marketplace.

Campos promocionais são opcionais.

Nunca criar preço anterior, desconto, comissão ou condição de pagamento para preencher visualmente o card.

Se o dado não existir ou não puder ser verificado, o campo deve permanecer ausente.

Amazon, Mercado Livre, Shopee e futuros marketplaces devem utilizar a mesma estrutura.

O Hermes deverá alimentar esse componente a partir da camada estruturada de dados, sem criar layouts diferentes para cada marketplace.



### Benefícios condicionais

Uma oferta pode possuir benefícios promocionais condicionais, como:

- desconto de primeira compra;
- desconto exclusivo de aplicativo;
- condição especial para assinantes;
- parcelamento exclusivo de cartão;
- cupom promocional;
- cashback ou incentivo temporário.

Esses benefícios não devem ser tratados como desconto universal do produto.

O card deve separar:

preço real observado
→ condição normal de pagamento
→ benefícios condicionais
→ observação das regras.

O Hermes deverá registrar explicitamente quando um benefício depender de cartão, assinatura, aplicativo, cupom, primeira compra ou outro requisito.



## Template Mercado Livre - padrão oficial

O padrão visual compacto originalmente utilizado no card Mercado Livre é o template oficial de todos os cards de oferta do Green Deals Brasil.

A estrutura deve permanecer igual para todos os marketplaces:

1. marketplace;
2. imagem;
3. status;
4. título;
5. resumo;
6. caixa comercial;
7. preço anterior, quando existir;
8. preço atual;
9. desconto, quando existir;
10. condição de pagamento;
11. parcelamento;
12. informações específicas do marketplace;
13. observação;
14. CTA.

A caixa comercial deve permanecer compacta.

Informações específicas não devem criar layouts diferentes.

Exemplos:

Amazon:
- parcelamento;
- cartão Amazon;
- benefício Prime;
- desconto de primeira compra;
- benefício do aplicativo.

Mercado Livre:
- desconto;
- Pix;
- parcelamento;
- loja oficial;
- volume vendido;
- ranking.

Shopee:
- cupom;
- moedas;
- frete;
- cashback;
- loja oficial.

Campos sem dado real devem ser omitidos.

Nunca criar informação apenas para preencher espaço.

O Hermes deverá usar este mesmo template para todas as ofertas futuras.

