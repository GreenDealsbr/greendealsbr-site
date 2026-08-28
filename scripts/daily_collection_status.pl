use strict;
use warnings;
use utf8;

use JSON::PP;

binmode STDOUT, ':encoding(UTF-8)';

my $offers_file =
    'data/ofertas.json';

my $analysis_file =
    'data/analysis/opportunities.json';


# ============================================================
# LEITURA
# ============================================================

open my $ofh, '<:raw', $offers_file
    or die "ERRO ao abrir $offers_file: $!\n";

my $offers_raw;
{
    local $/;
    $offers_raw = <$ofh>;
}

close $ofh;


open my $afh, '<:raw', $analysis_file
    or die "ERRO ao abrir $analysis_file: $!\n";

my $analysis_raw;
{
    local $/;
    $analysis_raw = <$afh>;
}

close $afh;


my $offers =
    decode_json($offers_raw);

my $analysis =
    decode_json($analysis_raw);


# ============================================================
# INDEX DA ANALISE
# ============================================================

my %analysis_by_offer;

for my $a (@{$analysis->{offers} || []}) {

    next unless
        defined $a->{offer_id};

    $analysis_by_offer{
        $a->{offer_id}
    } = $a;
}


my $minimum =
    $analysis->{methodology}
        ->{minimum_observations_for_classification}
    // 5;


# ============================================================
# CABECALHO
# ============================================================

print "\n";
print "============================================================\n";
print " GREEN DEALS BR - PAINEL DE COLETA DIARIA\n";
print "============================================================\n";

print "\n";
print "Minimo para classificacao: $minimum observacoes de preco\n";


# ============================================================
# OFERTAS
# ============================================================

for my $o (@{$offers->{offers} || []}) {

    my $id =
        $o->{id}
        // 'N/D';

    my $a =
        $analysis_by_offer{$id}
        || {};


    my $marketplace =
        $o->{marketplace}->{name}
        // $o->{marketplace}->{code}
        // 'N/D';


    my $product =
        $o->{product}->{title}
        // 'N/D';


    my $price =
        $o->{commercial}->{price_observed};


    my $price_at =
        $o->{commercial}->{price_observed_at}
        // 'N/D';


    my $availability =
        $o->{commercial}->{availability_observed}
        // 'N/D';


    my $checked =
        $o->{tracking}->{last_checked_at}
        // 'N/D';


    my $last_type =
        $o->{tracking}->{last_observation_type}
        // 'priced_offer';


    my $observations =
        $a->{observations}
        // 0;


    my $remaining =
        $minimum - $observations;

    $remaining = 0
        if $remaining < 0;


    my $classification =
        $a->{opportunity_classification}
        // 'N/D';


    print "\n";
    print "------------------------------------------------------------\n";

    print "$id\n";
    print "$marketplace\n";

    print "Produto: $product\n";

    print "Ultimo preco conhecido: ";

    if (defined $price) {

        printf "R\$ %.2f\n", $price;

    } else {

        print "N/D\n";
    }


    print "Preco observado em: $price_at\n";

    print "Disponibilidade atual: $availability\n";

    print "Ultima checagem: $checked\n";

    print "Ultimo tipo de evento: $last_type\n";

    print "Observacoes de preco: $observations / $minimum\n";

    print "Faltam para classificacao: $remaining\n";

    print "Classificacao atual: $classification\n";


    print "Acao recomendada: ";


    if (
        $availability eq 'sem_oferta_destacada'
        ||
        $availability eq 'fora_de_estoque'
        ||
        $availability eq 'indisponivel'
    ) {

        print
            "verificar se a oferta voltou; "
            . "se continuar indisponivel, registrar availability_only.\n";

    } else {

        print
            "verificar preco, disponibilidade e condicoes comerciais.\n";
    }
}


print "\n";
print "============================================================\n";
print " ROTINA RECOMENDADA: 1 COLETA REAL POR DIA / OFERTA\n";
print "============================================================\n";
