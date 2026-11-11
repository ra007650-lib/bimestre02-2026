--Função 3 — Atualizar locações atrasadas
-- Com essa função consigo alterar a situação de todas as loacações atrasadas

CREATE OR REPLACE FUNCTION atualizar_atraso_por_id(p_id INT)
RETURNS VOID AS $$
BEGIN
    UPDATE locacoes
    SET status = 'Atrasada'
    WHERE id_locacao = p_id
      AND status = 'Ativa'
      AND data_devolucao IS NULL
      AND data_prevista_devolucao < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

SELECT atualizar_atraso_por_id(3); -- não haverá alteração pois está "Concluída"!;

SELECT atualizar_atraso_por_id(9); -- Nesse caso funcionará pois como ela atende ao status 'Ativo',
								   -- ele faz a alteração para atrasado	

SELECT id_locacao, status, data_prevista_devolucao
FROM locacoes
WHERE id_locacao = 9;