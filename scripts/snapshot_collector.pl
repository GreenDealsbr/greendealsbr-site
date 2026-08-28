use strict;
use warnings;
use utf8;

use JSON::PP;
use Getopt::Long qw(GetOptions);

binmode STDOUT, ':encoding(UTF-8)';


# ============================================================
# ARGUMENTOS
# ============================================================


        my $input_file;
        my $input_marketplace;
        my $input_currency;

my $observation_type = 'priced_offer';
        my $offer_id;

my $price;
my $observed_at;
my $availability;
my $seller;

    my $source;


my $price_from;
my $discount_percent;
my $installments;
my $installment_value;
my $installment_total;
my $installments_interest;
my $rating;
my $reviews;
my $sold_quantity;


my $dry_run = 0;
my $apply = 0;
my $force = 0;



        GetOptions(

            'input=s'                   => \$input_file,


    'offer=s'                   => \$offer_id,
    'price=f'                   => \$price,
    'observed-at=s'             => \$observed_at,
    'availability=s'            => \$availability,
    'seller=s'                  => \$seller,
    'source=s'                  => \$source,

    'price-from=f'              => \$price_from,
    'discount-percent=f'        => \$discount_percent,

    'installments=i'            => \$installments,
    'installment-value=f'       => \$installment_value,
    'installment-total=f'       => \$installment_total,
    'installments-interest=s'   => \$installments_interest,

    'rating=f'                  => \$rating,
    'reviews=i'                 => \$reviews,
    'sold-quantity=s'           => \$sold_quantity,


'dry-run'                   => \$dry_run,
    'apply'                     => \$apply,
    'force'                     => \$force,

) or die "ERRO: argumentos invalidos.\n";

# ============================================================
# INPUT OBSERVATION CONTRACT V1
# ============================================================

if (defined $input_file) {

    -f $input_file
        or die "ERRO: arquivo de input nao encontrado: $input_file\n";


    open my $ifh, '<:raw', $input_file
        or die "ERRO: nao foi possivel abrir $input_file\n";


    my $input_raw;
    {
        local $/;
        $input_raw = <$ifh>;
    }
    close $ifh;


    my $input;

    eval {
        $input = decode_json($input_raw);
    };


    if ($@) {

        die
            "ERRO: input nao e JSON valido: "
            . $@
            . "\n";
    }


    # --------------------------------------------------------
    # CONTRACT VERSION
    # --------------------------------------------------------

    die "ERRO: contract_version deve ser 1.0 ou 1.1\n"
    unless
    defined $input->{contract_version}
    &&
    (
        $input->{contract_version} eq '1.0'
        ||
        $input->{contract_version} eq '1.1'
    );


if ($input->{contract_version} eq '1.1') {

    $observation_type =
        $input->{observation_type}
        // '';

    die "ERRO: observation_type invalido\n"
        unless
        $observation_type eq 'priced_offer'
        ||
        $observation_type eq 'availability_only';

} else {

    $observation_type =
        'priced_offer';
}



    # --------------------------------------------------------
    # CAMPOS PRINCIPAIS
    # --------------------------------------------------------

    my $contract_offer_id =
        $input->{offer_id};


    my $contract_marketplace =
        $input->{marketplace};


    my $contract_observed_at =
        $input->{observed_at};


    my $contract_source =
        $input->{source};


    die "ERRO: offer_id invalido no input\n"
        unless
        defined $contract_offer_id
        && $contract_offer_id
            =~ /^GDBR-OFFER-[0-9]{3,}$/;


    die "ERRO: marketplace invalido no input\n"
        unless
        defined $contract_marketplace
        && $contract_marketplace
            =~ /^[a-z0-9_]+$/;


    die "ERRO: observed_at invalido no input\n"
        unless
        defined $contract_observed_at
        && $contract_observed_at
            =~ /^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2})?$/;


    die "ERRO: source ausente no input\n"
        unless
        defined $contract_source
        && length $contract_source;


    # --------------------------------------------------------
    # COMMERCIAL
    # --------------------------------------------------------

    my $c =
        $input->{commercial}
        || {};


    die "ERRO: commercial.currency ausente\n"
        unless
        defined $c->{currency}
        && length $c->{currency};


    die "ERRO: commercial.availability ausente\n"
    unless
    defined $c->{availability}
    && length $c->{availability};


if ($observation_type eq 'priced_offer') {

    die "ERRO: commercial.price invalido\n"
        unless
        defined $c->{price}
        && $c->{price} > 0;


    die "ERRO: commercial.seller ausente\n"
        unless
        defined $c->{seller}
        && length $c->{seller};

} elsif ($observation_type eq 'availability_only') {

    die "ERRO: commercial.price deve ser omitido em availability_only\n"
        if exists $c->{price};


    my %allowed_availability = map {
        $_ => 1
    } qw(
        sem_oferta_destacada
        fora_de_estoque
        indisponivel
    );


    die "ERRO: availability invalida para availability_only\n"
        unless
        $allowed_availability{
            $c->{availability}
        };
}



    if (
        defined $c->{discount_percent}
        &&
        (
            $c->{discount_percent} < 0
            ||
            $c->{discount_percent} > 100
        )
    ) {

        die "ERRO: commercial.discount_percent fora de 0..100\n";
    }


    if (
        defined $c->{rating}
        &&
        (
            $c->{rating} < 0
            ||
            $c->{rating} > 5
        )
    ) {

        die "ERRO: commercial.rating fora de 0..5\n";
    }


    if (
        defined $c->{reviews}
        && $c->{reviews} < 0
    ) {

        die "ERRO: commercial.reviews nao pode ser negativo\n";
    }


    # --------------------------------------------------------
    # CONFLITOS ENTRE CLI E INPUT
    #
    # CLI continua permitido por compatibilidade.
    # Se ambos forem informados, nao podem divergir.
    # --------------------------------------------------------

    if (
        defined $offer_id
        && $offer_id ne $contract_offer_id
    ) {

        die "ERRO: --offer conflita com offer_id do input\n";
    }


    if ($observation_type eq 'priced_offer') {

    if (
        defined $price
        && (0 + $price) != (0 + $c->{price})
    ) {

        die "ERRO: --price conflita com commercial.price do input\n";
    }

} elsif (
    $observation_type eq 'availability_only'
    && defined $price
) {

    die "ERRO: --price nao pode ser usado com availability_only\n";
}



    if (
        defined $observed_at
        && $observed_at ne $contract_observed_at
    ) {

        die "ERRO: --observed-at conflita com observed_at do input\n";
    }


    if (
        defined $availability
        && $availability ne $c->{availability}
    ) {

        die "ERRO: --availability conflita com input\n";
    }


    if (
    defined $seller
    && defined $c->{seller}
    && $seller ne $c->{seller}
) {

    die "ERRO: --seller conflita com input\n";
}



    # --------------------------------------------------------
    # NORMALIZACAO PARA O COLLECTOR
    # --------------------------------------------------------

    $offer_id //=
        $contract_offer_id;


    if (
    $observation_type eq 'priced_offer'
    && defined $c->{price}
) {

    $price //=
        0 + $c->{price};
}



    $observed_at //=
        $contract_observed_at;


    $availability //=
        $c->{availability};


    if (defined $c->{seller}) {

    $seller //=
        $c->{seller};
}



    $source //=
        $contract_source;


    $input_marketplace =
        $contract_marketplace;


    $input_currency =
        $c->{currency};


    # --------------------------------------------------------
    # CAMPOS OPCIONAIS
    # --------------------------------------------------------

    $price_from //=
        $c->{price_from}
            if defined $c->{price_from};


    $discount_percent //=
        $c->{discount_percent}
            if defined $c->{discount_percent};


    if (
        defined $c->{installments}
        && ref $c->{installments} eq 'HASH'
    ) {

        $installments //=
            $c->{installments}->{count}
                if defined $c->{installments}->{count};


        $installment_value //=
            $c->{installments}->{value}
                if defined $c->{installments}->{value};


        $installment_total //=
            $c->{installments}->{total}
                if defined $c->{installments}->{total};


        $installments_interest //=
            $c->{installments}->{interest}
                if defined $c->{installments}->{interest};
    }


    $rating //=
        $c->{rating}
            if defined $c->{rating};


    $reviews //=
        $c->{reviews}
            if defined $c->{reviews};


    $sold_quantity //=
        $c->{sold_quantity}
            if defined $c->{sold_quantity};


    print "\n";
    print "Observation Contract carregado:\n";
    print "$input_file\n";
}

$source //=
    'manual_collector_v1';




# ============================================================
# FUNCOES
# ============================================================

sub fail {
    my ($msg) = @_;
    die "ERRO: $msg\n";
}


sub round2 {
    my ($value) = @_;
    return undef unless defined $value;
    return 0 + sprintf("%.2f", $value);
}


sub usage {

    print <<'TXT';


        Uso:

        Modo Observation Contract:

        perl scripts/snapshot_collector.pl \
          --input observation.json

        Escrita real:

        perl scripts/snapshot_collector.pl \
          --input observation.json \
          --apply

        Modo legado por argumentos:

perl scripts/snapshot_collector.pl \
  --offer GDBR-OFFER-001 \
  --price 699 \
  --observed-at 2026-08-27T22:30:00 \
  --availability em_estoque \
  --seller Master_Plants \
  --source manual_collector_v1 \
  --dry-run

Parametros obrigatorios:

--offer
--price
--observed-at
--availability
--seller

Parametros opcionais:

--source
--price-from
--discount-percent
--installments
--installment-value
--installment-total
--installments-interest
--rating
--reviews
--sold-quantity
--dry-run
--apply
--force

TXT

    exit 0;
}


# ============================================================
# VALIDACAO BASICA
# ============================================================

usage()
    unless defined $offer_id
    || defined $price
    || defined $observed_at;


fail("--offer obrigatorio")
    unless defined $offer_id
    && length $offer_id;


if ($observation_type eq 'priced_offer') {

    fail("--price obrigatorio")
        unless defined $price;


    fail("price deve ser maior que zero")
        unless $price > 0;

} elsif ($observation_type eq 'availability_only') {

    fail("price deve estar ausente em availability_only")
        if defined $price;
}



fail("--observed-at obrigatorio")
    unless defined $observed_at;


fail("observed-at deve usar YYYY-MM-DD ou ISO datetime")
    unless $observed_at =~
        /^\d{4}-\d{2}-\d{2}(?:T\d{2}:\d{2}:\d{2})?$/;


fail("--availability obrigatorio")
    unless defined $availability
    && length $availability;


if ($observation_type eq 'priced_offer') {

    fail("--seller obrigatorio")
        unless
        defined $seller
        && length $seller;
}



# ============================================================
# ARQUIVOS
# ============================================================

my $offers_file =
    'data/ofertas.json';


-f $offers_file
    or fail("$offers_file nao encontrado");


# ============================================================
# CARREGANDO ESTADO ATUAL
# ============================================================

open my $fh, '<:raw', $offers_file
    or fail("nao foi possivel abrir $offers_file");


my $raw;
{
    local $/;
    $raw = <$fh>;
}
close $fh;


my $data;

eval {
    $data = decode_json($raw);
};

fail("ofertas.json invalido: $@")
    if $@;


# ============================================================
# LOCALIZANDO OFERTA
# ============================================================

my $offer;

for my $candidate (@{$data->{offers} || []}) {

    if (
        defined $candidate->{id}
        && $candidate->{id} eq $offer_id
    ) {

        $offer = $candidate;
        last;
    }
}



        fail("oferta $offer_id nao encontrada")
    unless $offer;


if (defined $input_marketplace) {

    my $expected_marketplace =
        $offer->{marketplace}->{code}
        // '';


    fail(
        "marketplace do input nao corresponde "
        . "ao marketplace cadastrado para $offer_id"
    )
        unless
        $input_marketplace
        eq $expected_marketplace;
}


if (defined $input_currency) {

    my $expected_currency =
        $offer->{commercial}->{currency}
        // 'BRL';


    fail(
        "currency do input nao corresponde "
        . "a moeda cadastrada para $offer_id"
    )
        unless
        $input_currency
        eq $expected_currency;
}





my $history_file =
    $offer->{history}->{price_history_file}
    || "data/history/$offer_id.jsonl";


# ============================================================
# SNAPSHOT
# ============================================================

my $snapshot = {

    observation_type =>
        $observation_type,

    offer_id =>
        $offer_id,

    observed_at =>
        $observed_at,

    marketplace =>
        $offer->{marketplace}->{code},

    currency =>
        $offer->{commercial}->{currency}
        || 'BRL',

    availability =>
        $availability,

    source =>
        $source
};


if (
    $observation_type eq 'priced_offer'
    && defined $price
) {

    $snapshot->{price} =
        round2($price);
}


if (defined $seller) {

    $snapshot->{seller} =
        $seller;
}



$snapshot->{price_from} =
    round2($price_from)
        if defined $price_from;


$snapshot->{discount_percent} =
    round2($discount_percent)
        if defined $discount_percent;


$snapshot->{installments} =
    $installments
        if defined $installments;


$snapshot->{installment_value} =
    round2($installment_value)
        if defined $installment_value;


$snapshot->{installment_total} =
    round2($installment_total)
        if defined $installment_total;


$snapshot->{installments_interest} =
    $installments_interest
        if defined $installments_interest;


$snapshot->{rating} =
    round2($rating)
        if defined $rating;


$snapshot->{reviews} =
    $reviews
        if defined $reviews;


$snapshot->{sold_quantity} =
    $sold_quantity
        if defined $sold_quantity;


# ============================================================
# VERIFICANDO DUPLICIDADE
# ============================================================

my $duplicate = 0;


if (-f $history_file) {

    open my $hf, '<:encoding(UTF-8)', $history_file
        or fail("nao foi possivel abrir $history_file");


    while (my $line = <$hf>) {

        chomp $line;

        next unless $line =~ /\S/;


        my $existing;

        eval {
            $existing = decode_json($line);
        };

        next if $@;


        my $same_identity =
    ($existing->{offer_id} // '')
        eq $offer_id
    &&
    ($existing->{observed_at} // '')
        eq $observed_at;


next unless $same_identity;


if ($observation_type eq 'priced_offer') {

    if (
        defined $existing->{price}
        &&
        defined $price
        &&
        (0 + $existing->{price})
            == (0 + $price)
    ) {

        $duplicate = 1;
        last;
    }

} elsif ($observation_type eq 'availability_only') {

    if (
        !defined $existing->{price}
        &&
        ($existing->{availability} // '')
            eq ($availability // '')
    ) {

        $duplicate = 1;
        last;
    }
}

    }


    close $hf;
}


if ($duplicate && !$force) {

    fail(
        "snapshot duplicado detectado. "
        . "Use --force somente se houver motivo real."
    );
}


# ============================================================
# MOSTRANDO DIFERENCAS
# ============================================================

my $old_price =
    $offer->{commercial}->{price_observed};


my $old_date =
    $offer->{commercial}->{price_observed_at};


my $old_availability =
    $offer->{commercial}->{availability_observed};


my $old_seller =
    $offer->{commercial}->{seller_observed};


print "\n";
print "=================================================\n";
print " GDBR SNAPSHOT COLLECTOR V1\n";
print "=================================================\n";

print "\nOferta:\n";
print "$offer_id\n";

print "\nProduto:\n";
print(($offer->{product}->{title} // 'N/D') . "\n");

print "\nMarketplace:\n";
print(($offer->{marketplace}->{name} // 'N/D') . "\n");


print "\n--- ESTADO ATUAL ---\n";

print "Preco: ",
    defined $old_price
        ? "R\$ " . sprintf("%.2f", $old_price)
        : "N/D",
    "\n";

print "Observado em: ",
    ($old_date // 'N/D'),
    "\n";

print "Disponibilidade: ",
    ($old_availability // 'N/D'),
    "\n";

print "Vendedor: ",
    ($old_seller // 'N/D'),
    "\n";


print "\n--- NOVA OBSERVACAO ---\n";

if (defined $price) {

    print "Preco: R\$ ",
        sprintf("%.2f", $price),
        "\n";

} else {

    print "Preco: N/D (evento sem preco)\n";
}


print "Observado em: ",
    $observed_at,
    "\n";

print "Disponibilidade: ",
    $availability,
    "\n";

print "Vendedor: ",
    (defined $seller ? $seller : 'N/D'),
    "\n";


print "Fonte: ",
    $source,
    "\n";


print "\nHistorico:\n";
print "$history_file\n";



# ============================================================
# MODO DE EXECUCAO
# ============================================================

if (!$apply) {

    $dry_run = 1;


    print "\n";
    print "=============================================\n";
    print " DRY-RUN ATIVO - PADRAO SEGURO\n";
    print "=============================================\n";

    print "\nNenhum arquivo sera alterado.\nUse --apply somente para confirmar uma escrita real.\n";

    print "\nO collector faria:\n";

    print "1. validar a observacao\n";
    print "2. adicionar snapshot ao historico\n";
    print "3. atualizar estado atual em ofertas.json\n";
    print "4. atualizar tracking\n";
    print "5. executar Opportunity Engine\n";
    print "6. recalcular classificacao\n";

    print "\nOK: dry-run concluido.\n";

    exit 0;
}


# ============================================================
# ESCRITA REAL EXIGE --apply
# ============================================================

print "\n";
print "MODO APPLY CONFIRMADO.\n";
print "A operacao podera alterar a camada oficial de dados.\n";

# ============================================================
# PREPARANDO ESTADO NOVO
# ============================================================

if ($observation_type eq 'priced_offer') {

    $offer->{commercial}->{price_observed} =
        round2($price);

    $offer->{commercial}->{price_observed_at} =
        $observed_at;


    if (defined $seller) {

        $offer->{commercial}->{seller_observed} =
            $seller;
    }
}


$offer->{commercial}->{availability_observed} =
    $availability;



$offer->{tracking}->{last_checked_at} =
    $observed_at;

$offer->{tracking}->{last_collection_source} =
    $source;

$offer->{tracking}->{last_observation_type} =
    $observation_type;



$offer->{history}->{last_snapshot_at} =
    $observed_at;

$offer->{history}->{snapshot_source} =
    $source;


$offer->{automation}->{last_collector} =
    'snapshot_collector_v1';


my ($date_only) =
    $observed_at =~ /^(\d{4}-\d{2}-\d{2})/;


$data->{updated_at} =
    $date_only
        if defined $date_only;


# ============================================================
# VALIDANDO NOVO JSON ANTES DE GRAVAR
# ============================================================

my $encoder =
    JSON::PP
    ->new
    ->utf8
    ->canonical
    ->pretty;


my $new_json =
    $encoder->encode($data);


eval {
    decode_json($new_json);
};


fail("novo ofertas.json falhou na validacao")
    if $@;


# ============================================================
# SNAPSHOT JSONL
# ============================================================

my $snapshot_encoder =
    JSON::PP
    ->new
    ->utf8
    ->canonical;


my $snapshot_line =
    $snapshot_encoder->encode($snapshot);


$snapshot_line =~ s/\r?\n+\z//;


# ============================================================
# BACKUP TRANSACIONAL
# ============================================================

my $txn_dir =
    ".gdbr-collector-txn-$$";

mkdir $txn_dir
    or fail("nao foi possivel criar diretorio transacional");


my $backup_offers =
    "$txn_dir/ofertas.json";

my $backup_history =
    "$txn_dir/history.jsonl";

my $backup_analysis =
    "$txn_dir/opportunities.json";


use File::Copy qw(copy);


copy($offers_file, $backup_offers)
    or fail("nao foi possivel criar backup de ofertas.json");


if (-f $history_file) {

    copy($history_file, $backup_history)
        or fail("nao foi possivel criar backup do historico");
}


my $analysis_file =
    "data/analysis/opportunities.json";


if (-f $analysis_file) {

    copy($analysis_file, $backup_analysis)
        or fail("nao foi possivel criar backup da analise");
}


sub rollback_transaction {

    print "\nATENCAO: iniciando rollback...\n";


    if (-f $backup_offers) {

        copy($backup_offers, $offers_file);

        print "Rollback: ofertas.json restaurado.\n";
    }


    if (-f $backup_history) {

        copy($backup_history, $history_file);

        print "Rollback: historico restaurado.\n";
    }


    if (-f $backup_analysis) {

        copy($backup_analysis, $analysis_file);

        print "Rollback: analise restaurada.\n";
    }


    unlink $backup_offers
        if -f $backup_offers;

    unlink $backup_history
        if -f $backup_history;

    unlink $backup_analysis
        if -f $backup_analysis;

    rmdir $txn_dir
        if -d $txn_dir;
}


# ============================================================
# ESCREVENDO HISTORICO
# ============================================================

open my $history_out, '>>:raw', $history_file
    or fail("nao foi possivel escrever em $history_file");


print {$history_out}
    $snapshot_line,
    "\n";


close $history_out;


# ============================================================
# ESCREVENDO ESTADO ATUAL
# ============================================================

my $temp_file =
    "$offers_file.tmp";


open my $out, '>:raw', $temp_file
    or fail("nao foi possivel criar arquivo temporario");


print {$out}
    $new_json;


close $out;


rename $temp_file, $offers_file
    or fail("nao foi possivel substituir ofertas.json");


# ============================================================
# EXECUTANDO OPPORTUNITY ENGINE
# ============================================================

print "\nSnapshot registrado com sucesso.\n";

print "\nExecutando Opportunity Engine...\n";


my $engine_status =
    system(
        'perl',
        'scripts/opportunity_engine.pl'
    );


if ($engine_status != 0) {

    rollback_transaction();

    fail(
        "Opportunity Engine retornou erro. "
        . "Alteracoes foram revertidas."
    );
}


# ============================================================
# RESULTADO FINAL
# ============================================================

if (-f $analysis_file) {

    open my $af, '<:raw', $analysis_file
        or fail("nao foi possivel abrir relatorio");


    my $analysis_raw;
    {
        local $/;
        $analysis_raw = <$af>;
    }
    close $af;


    my $analysis =
        decode_json($analysis_raw);


    for my $result (@{$analysis->{offers} || []}) {

        next
            unless
            ($result->{offer_id} // '')
            eq $offer_id;


        print "\n";
        print "=============================================\n";
        print " RESULTADO ATUALIZADO\n";
        print "=============================================\n";

        print "Observacoes: ",
            ($result->{observations} // 0),
            "\n";

        print "Confianca: ",
            ($result->{evidence_level} // 'N/D'),
            "\n";

        print "Classificacao: ",
            ($result->{opportunity_classification} // 'N/D'),
            "\n";

        last;
    }
}



# ============================================================
# FINALIZANDO TRANSACAO COM SUCESSO
# ============================================================

for my $backup_file (
    $backup_offers,
    $backup_history,
    $backup_analysis
) {

    next unless
        defined $backup_file
        && length $backup_file;

    if (-f $backup_file) {

        unlink $backup_file
            or warn
                "ATENCAO: nao foi possivel remover "
                . "$backup_file: $!\n";
    }
}


if (-d $txn_dir) {

    rmdir $txn_dir
        or warn
            "ATENCAO: nao foi possivel remover "
            . "diretorio transacional $txn_dir: $!\n";
}


print "\n";
print "Transacao confirmada. Cleanup concluido.\n";

print "\n";
print "OK: Snapshot Collector V1 concluido.\n";
