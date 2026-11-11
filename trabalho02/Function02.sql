-- Função 2 — Calcular o valor da locação
-- Com essa função consigo efetuar o calculo do total de cada locação feita


CREATE OR REPLACE FUNCTION calcular_valor_locacao(p_id INT)
RETURNS TEXT AS $$
DECLARE
    v_dias INT;
    v_diaria NUMERIC(10,2);
    v_total NUMERIC(10,2);
BEGIN
    SELECT
        COALESCE(data_devolucao,
                 data_prevista_devolucao) - data_inicio
    INTO v_dias
    FROM locacoes
    WHERE id_locacao = p_id
      AND status <> 'Cancelada';

    IF NOT FOUND THEN
        RETURN 'Locação inexistente ou cancelada!';
    END IF;

    SELECT SUM(quantidade * valor_diaria)
    INTO v_diaria
    FROM itens_locacao
    WHERE id_locacao = p_id;

    v_total := COALESCE(v_diaria, 0) * v_dias;

    RETURN 'R$ ' ||
           REPLACE(
               TO_CHAR(v_total, 'FM999999990.00'),
               '.', ','
           );
END;
$$ LANGUAGE plpgsql;

-- Testes
SELECT calcular_valor_locacao(1);
SELECT calcular_valor_locacao(3);
SELECT calcular_valor_locacao(14);

