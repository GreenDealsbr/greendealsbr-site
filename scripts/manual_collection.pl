use strict;
use warnings;
use utf8;

use JSON::PP;
use POSIX qw(strftime);
use File::Path qw(make_path);
use File::Copy qw(move);
use Getopt::Long;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $help = 0;

GetOptions(
    'help' => \$help
) or die "ERRO: argumentos invalidos.\n";


sub usage {

    print <<"TXT";

Green Deals BR - Manual Collection Assistant V1

Uso:

  perl scripts/manual_collection.pl

O assistente:

  1. lista as ofertas;
  2. permite escolher priced_offer ou availability_only;
  3. cria Observation Contract V1.1;
  4. executa Snapshot Collector em dry-run;
  5. pede confirmacao antes do --apply;
  6. arquiva a observacao aceita;
  7. mostra o painel diario atualizado.

Nenhuma escrita real ocorre sem digitar:

  APLICAR

TXT
}


if ($help) {

    usage();
    exit 0;
}


my $offers_file =
    'data/ofertas.json';

my $collector =
    'scripts/snapshot_collector.pl';

my $status_script =
    'scripts/daily_collection_status.pl';


# ============================================================
# FUNCOES
# ============================================================

sub read_json_file {

    my ($file) = @_;

    open my $fh, '<:raw', $file
        or die "ERRO ao abrir $file: $!\n";

    my $raw;

    {
        local $/;
        $raw = <$fh>;
    }

    close $fh;

    return decode_json($raw);
}


sub prompt {

    my ($label, $default) = @_;

    if (
        defined $default
        && length $default
    ) {

        print "$label [$default]: ";

    } else {

        print "$label: ";
    }


    my $value = <STDIN>;

    die "\nOperacao cancelada.\n"
        unless defined $value;

    chomp $value;


    if (
        !length $value
        && defined $default
    ) {

        return $default;
    }


    return $value;
}


sub required_prompt {

    my ($label, $default) = @_;

    while (1) {

        my $value =
            prompt($label, $default);

        return $value
            if defined $value
            && length $value;

        print "Valor obrigatorio.\n";
    }
}


sub run_command {

    my (@cmd) = @_;

    my $rc =
        system(@cmd);

    if ($rc == -1) {

        return 255;
    }

    return $rc >> 8;
}


sub numeric_value {

    my ($value) = @_;

    $value =~ s/,/./g;

    return undef
        unless
        $value =~ /^\d+(?:\.\d+)?$/;

    return 0 + $value;
}


# ============================================================
# CARREGANDO OFERTAS
# ============================================================

my $data =
    read_json_file($offers_file);

my @offers =
    @{$data->{offers} || []};


die "ERRO: nenhuma oferta cadastrada.\n"
    unless @offers;


print "\n";
print "============================================================\n";
print " GREEN DEALS BR - COLETA MANUAL ASSISTIDA\n";
print "============================================================\n";


print "\nOfertas disponíveis:\n\n";


for my $i (0 .. $#offers) {

    my $o =
        $offers[$i];

    my $id =
        $o->{id}
        // 'N/D';

    my $marketplace =
        $o->{marketplace}->{name}
        // $o->{marketplace}->{code}
        // 'N/D';

    my $title =
        $o->{product}->{title}
        // 'N/D';

    my $price =
        $o->{commercial}->{price_observed};

    my $availability =
        $o->{commercial}->{availability_observed}
        // 'N/D';


    print (($i + 1) . ". $id\n");
    print "   $marketplace\n";
    print "   $title\n";

    if (defined $price) {

        printf "   Ultimo preco: R\$ %.2f\n",
            $price;

    } else {

        print "   Ultimo preco: N/D\n";
    }

    print "   Disponibilidade: $availability\n";
    print "\n";
}


# ============================================================
# ESCOLHA DA OFERTA
# ============================================================

my $selected_index;

while (1) {

    my $choice =
        required_prompt(
            "Escolha a oferta pelo numero",
            undef
        );


    if (
        $choice =~ /^\d+$/
        &&
        $choice >= 1
        &&
        $choice <= scalar(@offers)
    ) {

        $selected_index =
            $choice - 1;

        last;
    }


    print "Opcao invalida.\n";
}


my $offer =
    $offers[$selected_index];


my $offer_id =
    $offer->{id};


my $marketplace =
    $offer->{marketplace}->{code};


my $product_title =
    $offer->{product}->{title}
    // 'N/D';


print "\n";
print "Oferta selecionada:\n";
print "$offer_id\n";
print "$product_title\n";


# ============================================================
# TIPO DE OBSERVACAO
# ============================================================

print "\n";
print "Tipo de observacao:\n";
print "1. priced_offer\n";
print "2. availability_only\n";


my $type_choice;

while (1) {

    $type_choice =
        required_prompt(
            "Escolha 1 ou 2",
            undef
        );


    last
        if
        $type_choice eq '1'
        ||
        $type_choice eq '2';


    print "Opcao invalida.\n";
}


my $observation_type =
    $type_choice eq '1'
    ? 'priced_offer'
    : 'availability_only';


# ============================================================
# DATA / HORA
# ============================================================

my $observed_at =
    strftime(
        "%Y-%m-%dT%H:%M:%S",
        localtime
    );


# ============================================================
# COMMERCIAL
# ============================================================

my $commercial = {

    currency =>
        $offer->{commercial}->{currency}
        // 'BRL'
};


if ($observation_type eq 'priced_offer') {

    my $price;

    while (1) {

        my $input_price =
            required_prompt(
                "Preco atual",
                undef
            );


        $price =
            numeric_value($input_price);


        if (
            defined $price
            && $price > 0
        ) {

            last;
        }


        print "Preco invalido.\n";
    }


    my $default_seller =
        $offer->{commercial}->{seller_observed}
        // '';


    my $seller =
        required_prompt(
            "Vendedor",
            $default_seller
        );


    my $availability =
        required_prompt(
            "Disponibilidade",
            "em_estoque"
        );


    $commercial->{price} =
        $price;

    $commercial->{seller} =
        $seller;

    $commercial->{availability} =
        $availability;

}
else {

    print "\n";
    print "Estado de disponibilidade:\n";
    print "1. sem_oferta_destacada\n";
    print "2. fora_de_estoque\n";
    print "3. indisponivel\n";


    my %status_map = (

        1 => 'sem_oferta_destacada',
        2 => 'fora_de_estoque',
        3 => 'indisponivel'
    );


    my $status_choice;

    while (1) {

        $status_choice =
            required_prompt(
                "Escolha 1, 2 ou 3",
                undef
            );


        last
            if exists
            $status_map{$status_choice};


        print "Opcao invalida.\n";
    }


    $commercial->{availability} =
        $status_map{$status_choice};
}


# ============================================================
# OBSERVATION CONTRACT
# ============================================================

my $observation = {

    contract_version =>
        '1.1',

    observation_type =>
        $observation_type,

    offer_id =>
        $offer_id,

    marketplace =>
        $marketplace,

    observed_at =>
        $observed_at,

    source =>
        'manual_collection_assistant_v1',

    product_title =>
        $product_title,

    commercial =>
        $commercial,

    links => {

        product_url =>
            $offer->{links}->{product_url},

        affiliate_url =>
            $offer->{links}->{affiliate_url}
    },

    provenance => {

        collector =>
            'manual_collection_assistant_v1',

        captured_at =>
            $observed_at,

        confidence =>
            'human_verified'
    }
};


# ============================================================
# SALVANDO EM INCOMING
# ============================================================

make_path(
    'data/incoming'
);


my $safe_time =
    $observed_at;

$safe_time =~ s/:/-/g;


my $incoming_file =
    "data/incoming/"
    . "$offer_id-$safe_time-$observation_type.json";


open my $out, '>:raw', $incoming_file
    or die
        "ERRO ao criar $incoming_file: $!\n";


print {$out}
    JSON::PP
        ->new
        ->utf8
        ->pretty
        ->canonical
        ->encode($observation);


close $out;


print "\n";
print "Observation Contract criado:\n";
print "$incoming_file\n";


# ============================================================
# RESUMO
# ============================================================

print "\n";
print "------------------------------------------------------------\n";
print "RESUMO DA OBSERVACAO\n";
print "------------------------------------------------------------\n";

print "Oferta: $offer_id\n";
print "Marketplace: $marketplace\n";
print "Tipo: $observation_type\n";
print "Observado em: $observed_at\n";

print "Disponibilidade: ",
    $commercial->{availability},
    "\n";


if (
    $observation_type
    eq 'priced_offer'
) {

    printf "Preco: R\$ %.2f\n",
        $commercial->{price};

    print "Vendedor: ",
        $commercial->{seller},
        "\n";
}
else {

    print "Preco: AUSENTE\n";
}


# ============================================================
# DRY-RUN
# ============================================================

print "\n";
print "============================================================\n";
print " DRY-RUN DO SNAPSHOT COLLECTOR\n";
print "============================================================\n";


my $dry_status =
    run_command(
        'perl',
        $collector,
        '--input',
        $incoming_file
    );


if ($dry_status != 0) {

    print "\n";
    print "ERRO: dry-run falhou.\n";
    print "Nenhuma escrita real foi executada.\n";
    print "Arquivo preservado para diagnostico:\n";
    print "$incoming_file\n";

    exit $dry_status;
}


print "\n";
print "Dry-run aprovado.\n";


# ============================================================
# CONFIRMACAO HUMANA
# ============================================================

print "\n";
print "Para gravar esta observacao na base oficial,\n";
print "digite exatamente:\n\n";
print "APLICAR\n\n";


my $confirmation =
    prompt(
        "Confirmacao",
        undef
    );


if ($confirmation ne 'APLICAR') {

    print "\n";
    print "Operacao cancelada.\n";
    print "Nenhum dado oficial foi alterado.\n";

    unlink $incoming_file;

    rmdir 'data/incoming';

    exit 0;
}


# ============================================================
# APPLY
# ============================================================

print "\n";
print "============================================================\n";
print " APPLY REAL\n";
print "============================================================\n";


my $apply_status =
    run_command(
        'perl',
        $collector,
        '--input',
        $incoming_file,
        '--apply'
    );


if ($apply_status != 0) {

    print "\n";
    print "ERRO: apply falhou.\n";
    print "Observation Contract mantido em incoming.\n";

    exit $apply_status;
}


# ============================================================
# ARQUIVAMENTO
# ============================================================

my $date_dir =
    strftime(
        "%Y-%m-%d",
        localtime
    );


my $archive_dir =
    "data/observations/accepted/$date_dir";


make_path(
    $archive_dir
);


my $archive_file =
    "$archive_dir/"
    . "$offer_id-$safe_time-$observation_type.json";


move(
    $incoming_file,
    $archive_file
)
or die
    "ERRO ao arquivar observacao: $!\n";


rmdir 'data/incoming';


print "\n";
print "Observation Contract arquivado:\n";
print "$archive_file\n";


# ============================================================
# PAINEL ATUALIZADO
# ============================================================

if (-f $status_script) {

    print "\n";
    print "============================================================\n";
    print " PAINEL ATUALIZADO\n";
    print "============================================================\n";

    run_command(
        'perl',
        $status_script
    );
}


# ============================================================
# GIT STATUS
# ============================================================

print "\n";
print "============================================================\n";
print " ALTERACOES LOCAIS\n";
print "============================================================\n";

run_command(
    'git',
    'status',
    '--short'
);


print "\n";
print "============================================================\n";
print " COLETA MANUAL CONCLUIDA\n";
print " NENHUM COMMIT OU PUSH FOI FEITO\n";
print "============================================================\n";
