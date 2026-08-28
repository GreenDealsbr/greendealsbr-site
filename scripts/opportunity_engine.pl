use strict;
use warnings;
use utf8;
use JSON::PP;

binmode STDOUT, ':encoding(UTF-8)';

my $offers_file = 'data/ofertas.json';
my $output_file = 'data/analysis/opportunities.json';


# ============================================================
# FUNCOES
# ============================================================

sub round2 {
    my ($n) = @_;
    return undef unless defined $n;
    return 0 + sprintf("%.2f", $n);
}


sub percent_change {
    my ($current, $base) = @_;

    return undef
        unless defined $current
        && defined $base
        && $base != 0;

    return round2((($current - $base) / $base) * 100);
}


sub evidence_level {
    my ($count) = @_;

    return 'insuficiente' if $count < 3;
    return 'baixa'        if $count < 5;
    return 'media'        if $count < 10;
    return 'alta';
}


sub classify_opportunity {
    my ($count, $current, $previous_avg, $previous_min) = @_;

    # --------------------------------------------------------
    # REGRA DE SEGURANCA
    #
    # O motor nao deve classificar uma promocao com base
    # em poucas observacoes.
    # --------------------------------------------------------

    return 'historico_insuficiente'
        if $count < 5;

    return 'historico_insuficiente'
        unless defined $previous_avg
        && defined $previous_min
        && defined $current;


    my $vs_avg =
        (($current - $previous_avg) / $previous_avg) * 100;


    # --------------------------------------------------------
    # OPORTUNIDADE EXCEPCIONAL
    #
    # Pelo menos 15% abaixo da media anterior
    # E igual ou abaixo do menor preco anterior.
    # --------------------------------------------------------

    if (
        $vs_avg <= -15
        && $current <= $previous_min
    ) {
        return 'oportunidade_excepcional';
    }


    # --------------------------------------------------------
    # BOA OFERTA
    # --------------------------------------------------------

    if ($vs_avg <= -10) {
        return 'boa_oferta';
    }


    # --------------------------------------------------------
    # INTERESSANTE
    # --------------------------------------------------------

    if ($vs_avg <= -5) {
        return 'interessante';
    }


    # --------------------------------------------------------
    # PRECO NORMAL
    # --------------------------------------------------------

    return 'preco_normal';
}


# ============================================================
# CARREGANDO OFERTAS
# ============================================================

open my $fh, '<:raw', $offers_file
    or die "ERRO ao abrir $offers_file: $!\n";

my $raw;
{
    local $/;
    $raw = <$fh>;
}
close $fh;

my $data = decode_json($raw);

my @results;


# ============================================================
# ANALISANDO CADA OFERTA
# ============================================================

for my $offer (@{$data->{offers} || []}) {

    my $id =
        $offer->{id}
        // next;

    my $history_file =
        $offer->{history}->{price_history_file}
        // next;


    my @snapshots;


    # --------------------------------------------------------
    # LENDO HISTORICO JSONL
    # --------------------------------------------------------

    if (-f $history_file) {

        open my $hf, '<:encoding(UTF-8)', $history_file
            or die "ERRO ao abrir $history_file: $!\n";

        while (my $line = <$hf>) {

            chomp $line;

            next unless $line =~ /\S/;

            my $snapshot;

            eval {
                $snapshot = decode_json($line);
            };

            if ($@) {
                warn "JSON invalido ignorado em $history_file\n";
                next;
            }

            next unless defined $snapshot->{price};

            push @snapshots, $snapshot;
        }

        close $hf;
    }


    # --------------------------------------------------------
    # ORDENANDO POR DATA
    # --------------------------------------------------------

    @snapshots = sort {
        ($a->{observed_at} // '')
        cmp
        ($b->{observed_at} // '')
    } @snapshots;


    my $count = scalar @snapshots;


    # --------------------------------------------------------
    # PRECOS
    # --------------------------------------------------------

    my @prices =
        map { 0 + $_->{price} }
        @snapshots;


    my $current =
        $count
        ? $prices[-1]
        : undef;


    my $minimum;
    my $maximum;
    my $average;


    if (@prices) {

        $minimum = $prices[0];
        $maximum = $prices[0];

        my $sum = 0;

        for my $p (@prices) {

            $minimum = $p if $p < $minimum;
            $maximum = $p if $p > $maximum;

            $sum += $p;
        }

        $average =
            $sum / scalar(@prices);
    }


    # --------------------------------------------------------
    # HISTORICO ANTERIOR AO PRECO ATUAL
    # --------------------------------------------------------

    my @previous =
        @prices > 1
        ? @prices[0 .. $#prices - 1]
        : ();


    my $previous_price =
        @previous
        ? $previous[-1]
        : undef;


    my $previous_average;
    my $previous_minimum;


    if (@previous) {

        my $sum = 0;

        $previous_minimum = $previous[0];

        for my $p (@previous) {

            $sum += $p;

            $previous_minimum = $p
                if $p < $previous_minimum;
        }

        $previous_average =
            $sum / scalar(@previous);
    }


    # --------------------------------------------------------
    # CLASSIFICACAO
    # --------------------------------------------------------

    my $classification =
        classify_opportunity(
            $count,
            $current,
            $previous_average,
            $previous_minimum
        );


    # --------------------------------------------------------
    # RESULTADO
    # --------------------------------------------------------

    push @results, {

        offer_id =>
            $id,

        marketplace =>
            $offer->{marketplace}->{code},

        product =>
            $offer->{product}->{title},

        observations =>
            $count,

        evidence_level =>
            evidence_level($count),

        current_price =>
            round2($current),

        historical_min =>
            round2($minimum),

        historical_max =>
            round2($maximum),

        historical_average =>
            round2($average),

        previous_price =>
            round2($previous_price),

        previous_average =>
            round2($previous_average),

        change_vs_previous_percent =>
            percent_change(
                $current,
                $previous_price
            ),

        change_vs_previous_average_percent =>
            percent_change(
                $current,
                $previous_average
            ),

        marketplace_discount_claim =>
            $offer->{commercial}->{discount_percent_observed},

        opportunity_classification =>
            $classification,

        engine_version =>
            '1.0',

        decision_basis =>
            $classification eq 'historico_insuficiente'
            ? 'dados_historicos_insuficientes'
            : 'historico_de_precos'
    };
}


# ============================================================
# RELATORIO
# ============================================================

my $report = {

    engine =>
        'GDBR Opportunity Engine',

    version =>
        '1.0',

    generated_from_schema =>
        $data->{schema_version},

    methodology => {

        minimum_observations_for_classification =>
            5,

        interesting_threshold_percent =>
            -5,

        good_offer_threshold_percent =>
            -10,

        exceptional_threshold_percent =>
            -15,

        exceptional_requires_new_historical_low =>
            JSON::PP::true
    },

    offers =>
        \@results
};


# ============================================================
# SALVANDO
# ============================================================

my $encoder =
    JSON::PP
    ->new
    ->utf8
    ->pretty
    ->canonical;


open my $out, '>:raw', $output_file
    or die "ERRO ao gravar $output_file: $!\n";

print {$out} $encoder->encode($report);

close $out;


# ============================================================
# TERMINAL
# ============================================================

print "\n";
print "=============================================\n";
print " GDBR OPPORTUNITY ENGINE V1\n";
print "=============================================\n";

for my $r (@results) {

    print "\n";
    print "---------------------------------------------\n";

    print "Oferta: ",
        $r->{offer_id},
        "\n";

    print "Produto: ",
        ($r->{product} // ''),
        "\n";

    print "Marketplace: ",
        ($r->{marketplace} // ''),
        "\n";

    print "Observacoes: ",
        $r->{observations},
        "\n";

    print "Confianca: ",
        $r->{evidence_level},
        "\n";

    print "Preco atual: R\$ ",
        defined $r->{current_price}
        ? sprintf("%.2f", $r->{current_price})
        : "N/D",
        "\n";

    print "Media historica: R\$ ",
        defined $r->{historical_average}
        ? sprintf("%.2f", $r->{historical_average})
        : "N/D",
        "\n";

    print "Menor preco: R\$ ",
        defined $r->{historical_min}
        ? sprintf("%.2f", $r->{historical_min})
        : "N/D",
        "\n";

    print "Classificacao: ",
        $r->{opportunity_classification},
        "\n";

    if (
        defined
        $r->{marketplace_discount_claim}
    ) {

        print "Desconto anunciado pelo marketplace: ",
            $r->{marketplace_discount_claim},
            "%\n";

        if (
            $r->{opportunity_classification}
            eq 'historico_insuficiente'
        ) {

            print
              "Validacao GDBR: desconto ainda nao confirmado pelo historico.\n";
        }
    }
}

print "\n";
print "Relatorio salvo em:\n";
print "$output_file\n";

print "\n";
print "OK: Opportunity Engine executado.\n";
