-- Função 1 — Consultar situação da locação
-- Com essa função consigo checar a situação de locação de todos os meus produtos

CREATE OR REPLACE FUNCTION consultar_locacao(p_id INT)
RETURNS TEXT AS $$
DECLARE
    v_cliente TEXT;
    v_status VARCHAR(20);
BEGIN
    SELECT c.nome, l.status
    INTO v_cliente, v_status
    FROM locacoes l
    JOIN clientes c ON c.id_cliente = l.id_cliente
    WHERE l.id_locacao = p_id;

    IF NOT FOUND THEN
        RETURN 'Locação não encontrada!';
    END IF;

    RETURN 'Cliente: ' || v_cliente ||
           ' - Situação: ' || v_status;
END;
$$ LANGUAGE plpgsql;

-- Testes
SELECT consultar_locacao(1);
SELECT consultar_locacao(5);
SELECT consultar_locacao(7);
SELECT consultar_locacao(14);
