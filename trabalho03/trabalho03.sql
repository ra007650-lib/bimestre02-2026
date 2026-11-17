-- TRABALHO PRÁTICO 03 - OPERADORES E FUNÇÕES POSTGRESQL



-- QUESTÃO 1 - Precedência lógica com parênteses
-- Identificar equipamentos disponíveis ou alugados cuja diária
-- seja de pelo menos R$ 20,00.
-- Sem os parênteses, todos os disponíveis seriam selecionados,
-- independentemente do preço, pois AND tem prioridade sobre OR.
-- Nesse caso, o valor mínimo seria aplicado somente aos alugados.

SELECT
    nome,
    status,
    valor_diaria
FROM equipamentos
WHERE (status = 'Disponivel' OR status = 'Alugado')
  AND valor_diaria >= 20.00
ORDER BY valor_diaria DESC;


-- QUESTÃO 2 - Negação e verificação de nulos
-- Localizar locações que ainda não possuem data de devolução,
-- excluindo as canceladas e as concluídas.
-- A coluna data_devolucao é opcional no banco da TechRent.

SELECT
    id_locacao,
    id_cliente,
    data_inicio,
    data_prevista_devolucao,
    status
FROM locacoes
WHERE status NOT IN ('Cancelada', 'Concluida')
  AND data_devolucao IS NULL
ORDER BY data_prevista_devolucao;


-- QUESTÃO 3 - Intervalos inclusivos e listas
-- Consultar equipamentos Dell, Lenovo ou Acer com diárias
-- entre R$ 30,00 e R$ 40,00, incluindo os dois limites.

SELECT
    nome,
    marca,
    valor_diaria
FROM equipamentos
WHERE valor_diaria BETWEEN 30.00 AND 40.00
  AND marca IN ('Dell', 'Lenovo', 'Acer')
ORDER BY valor_diaria;


-- QUESTÃO 4A - Busca com ILIKE e %
-- Localizar equipamentos que contenham "notebook" em qualquer
-- posição do nome, sem diferenciar maiúsculas e minúsculas.

SELECT
    id_equipamento,
    nome,
    marca,
    valor_diaria
FROM equipamentos
WHERE nome ILIKE '%notebook%'
ORDER BY nome;


-- QUESTÃO 4B - Busca com o curinga _
-- Localizar equipamentos Logitech cujo número de série
-- comece com LG-, seguido de quatro caracteres, outro hífen
-- e quatro caracteres finais.
-- Cada _ representa exatamente um caractere, não apenas dígitos.
-- Exemplo compatível: LG-K380-0004.

SELECT
    nome,
    numero_serie
FROM equipamentos
WHERE numero_serie LIKE 'LG-____-____'
ORDER BY numero_serie;


-- QUESTÃO 5 - Simulação numérica e arredondamentos
-- Simular um reajuste de 7,5% nas diárias dos equipamentos.
-- ROUND arredonda para duas casas decimais.
-- TRUNC corta as casas excedentes sem arredondar.
-- Esta consulta apenas simula; não altera os preços cadastrados.

SELECT
    nome,
    valor_diaria AS diaria_original,
    ROUND(valor_diaria * 1.075, 2) AS diaria_arredondada,
    TRUNC(valor_diaria * 1.075, 2) AS diaria_truncada
FROM equipamentos
ORDER BY nome;


-- QUESTÃO 6A - Classificação por módulo
-- Dividir os equipamentos em dois grupos para organizar
-- a conferência do estoque: códigos pares e códigos ímpares.
-- MOD retorna o resto da divisão do código por 2.

SELECT
    id_equipamento,
    nome,
    CASE
        WHEN MOD(id_equipamento, 2) = 0 THEN 'Grupo A - Par'
        ELSE 'Grupo B - Impar'
    END AS grupo_conferencia
FROM equipamentos
ORDER BY id_equipamento;


-- QUESTÃO 6B - Sorteio com RANDOM()
-- Sortear um equipamento disponível para destaque promocional.
-- Disponivel identifica um equipamento ativo e apto para locação.
-- O resultado pode mudar a cada execução.

SELECT
    id_equipamento,
    nome,
    valor_diaria,
    status
FROM equipamentos
WHERE status = 'Disponivel'
ORDER BY RANDOM()
LIMIT 1;


-- QUESTÃO 7 - Concatenação, padronização e extração
-- Montar uma identificação do cliente com seu telefone,
-- padronizar o nome em maiúsculas e extrair o primeiro nome.
-- CONCAT mantém a descrição mesmo se o telefone for NULL.

SELECT
    id_cliente,
    CONCAT(nome, ' | Telefone: ', telefone) AS identificacao,
    UPPER(nome) AS nome_maiusculo,
    SPLIT_PART(nome, ' ', 1) AS primeiro_nome
FROM clientes
ORDER BY nome;


-- QUESTÃO 8 - Extração temporal e janela de período
-- Consultar locações iniciadas nos últimos 30 dias até hoje.
-- Como data_inicio é DATE, usamos CURRENT_DATE como referência.
-- EXTRACT obtém ano e mês; DATE_TRUNC identifica o início do mês.
-- O limite superior exclui datas futuras.

SELECT
    id_locacao,
    data_inicio,
    EXTRACT(YEAR FROM data_inicio) AS ano_locacao,
    EXTRACT(MONTH FROM data_inicio) AS mes_locacao,
    DATE_TRUNC('month', data_inicio)::DATE AS inicio_mes,
    status
FROM locacoes
WHERE data_inicio >= CURRENT_DATE - INTERVAL '30 days'
  AND data_inicio <= CURRENT_DATE
ORDER BY data_inicio DESC;


-- QUESTÃO 9 - Tempo decorrido e projeção futura
-- Calcular há quanto tempo cada cliente está cadastrado
-- e projetar a data de revisão cadastral, um ano após o cadastro.
-- A data projetada pode já ter passado para cadastros antigos.

SELECT
    nome,
    data_cadastro,
    AGE(NOW(), data_cadastro) AS tempo_cadastrado,
    (data_cadastro + INTERVAL '1 year')::DATE
        AS data_revisao_cadastral
FROM clientes
ORDER BY data_cadastro;


-- QUESTÃO 10 - Relatório gerencial formatado
-- Exibir pagamentos recebidos, identificando o cliente
-- e a locação correspondente por meio de INNER JOIN.
-- Formatar datas no padrão brasileiro e códigos com zeros.
-- FM remove espaços do número formatado.
-- REPLACE troca o ponto decimal por vírgula, mantendo a
-- apresentação brasileira sem depender da configuração regional.

SELECT
    'PAG-' || LPAD(p.id_pagamento::TEXT, 4, '0')
        AS codigo_pagamento,
    'LOC-' || LPAD(l.id_locacao::TEXT, 4, '0')
        AS codigo_locacao,
    c.nome AS cliente,
    TO_CHAR(p.data_pagamento, 'DD/MM/YYYY')
        AS data_pagamento,
    'R$ ' || REPLACE(
        TO_CHAR(p.valor, 'FM999999990.00'),
        '.',
        ','
    ) AS valor_recebido,
    p.forma_pagamento,
    p.status AS situacao_pagamento
FROM pagamentos p
INNER JOIN locacoes l
    ON l.id_locacao = p.id_locacao
INNER JOIN clientes c
    ON c.id_cliente = l.id_cliente
WHERE p.status = 'Pago'
ORDER BY p.data_pagamento, p.id_pagamento;