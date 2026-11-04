/* =====================================================================
   TRABALHO PRÁTICO 01 - Gestão de Banco de Dados (PostgreSQL)
   Banco de dados: TechRent - Locação de Equipamentos Eletrônicos
   2º Bimestre / 2026
   ---------------------------------------------------------------------
   JUSTIFICATIVA DA ESCOLHA DO TEMA
   Escolhi esse tema por ser um negócio real, área de interesse e
   otimo para usar os relacionamentos: a locação de eletrônicos permite modelar
   clientes, estoque, preços, contratos, pagamentos e, principalmente,
   uma regra de negócio interessante (item avulso OU kit) que exige
   restrições de integridade bem pensadas.

   CONTEXTUALIZAÇÃO DO NEGÓCIO
   A TechRent é uma empresa fictícia que aluga eletrônicos por diária,
   com foco em estudantes e profissionais que precisam de equipamento
   por um período curto, sem comprar. O cliente pode alugar:
     - um equipamento individual (ex.: Notebook Dell Inspiron - R$ 35/dia);
     - um kit pronto (ex.: Kit Estudante = notebook + teclado + mouse
       - R$ 45/dia; Kit Gamer = computador + monitor + periféricos
       - R$ 85/dia).
   O banco controla o cadastro de clientes, o catálogo (categorias,
   equipamentos e kits), as locações com seus itens e os pagamentos.

   ESTRUTURA (8 tabelas, conforme o DER):
   CLIENTES, CATEGORIAS, EQUIPAMENTOS, KITS, ITENS_KIT,
   LOCACOES, ITENS_LOCACAO, PAGAMENTOS
   ===================================================================== */


/* ---------------------------------------------------------------------
   0. LIMPEZA (permite executar o script várias vezes sem erro)
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS pagamentos     CASCADE;
DROP TABLE IF EXISTS itens_locacao  CASCADE;
DROP TABLE IF EXISTS locacoes       CASCADE;
DROP TABLE IF EXISTS itens_kit      CASCADE;
DROP TABLE IF EXISTS kits           CASCADE;
DROP TABLE IF EXISTS equipamentos   CASCADE;
DROP TABLE IF EXISTS categorias     CASCADE;
DROP TABLE IF EXISTS clientes       CASCADE;


/* =====================================================================
   1. CRIAÇÃO DAS TABELAS
   ===================================================================== */

/* ---------------------------------------------------------------------
   CLIENTES
   Objetivo: guardar o cadastro das pessoas que alugam equipamentos.
   Finalidade: identificar quem fez cada locação e permitir contato
   (telefone/e-mail). CPF e e-mail são únicos para evitar duplicidade.
   A instituição de ensino registra o vínculo do estudante, que é o
   público principal da empresa.
   --------------------------------------------------------------------- */
CREATE TABLE clientes (
    id_cliente        SERIAL        PRIMARY KEY,
    nome              VARCHAR(100)  NOT NULL,
    cpf               VARCHAR(11)   NOT NULL UNIQUE,
    telefone          VARCHAR(15),
    email             VARCHAR(100)  NOT NULL UNIQUE,
    instituicao_ensino VARCHAR(100),
    data_cadastro     DATE          NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT ck_clientes_cpf   CHECK (cpf ~ '^[0-9]{11}$'),
    CONSTRAINT ck_clientes_email CHECK (email LIKE '%_@_%.__%')
);

/* ---------------------------------------------------------------------
   CATEGORIAS
   Objetivo: agrupar os equipamentos por tipo (notebooks, periféricos...).
   Finalidade: organizar o catálogo e permitir relatórios por tipo de
   equipamento.
   --------------------------------------------------------------------- */
CREATE TABLE categorias (
    id_categoria  SERIAL        PRIMARY KEY,
    nome          VARCHAR(60)   NOT NULL UNIQUE,
    descricao     VARCHAR(200)
);

/* ---------------------------------------------------------------------
   EQUIPAMENTOS
   Objetivo: cadastrar cada unidade física disponível para locação.
   Finalidade: controlar o estoque individual (número de série único),
   o valor da diária, o estado de conservação e se o item está
   disponível, alugado ou em manutenção.
   --------------------------------------------------------------------- */
CREATE TABLE equipamentos (
    id_equipamento      SERIAL         PRIMARY KEY,
    id_categoria        INTEGER        NOT NULL,
    nome                VARCHAR(100)   NOT NULL,
    marca               VARCHAR(50)    NOT NULL,
    modelo              VARCHAR(80),
    numero_serie        VARCHAR(40)    NOT NULL UNIQUE,
    valor_diaria        NUMERIC(10,2)  NOT NULL,
    estado_conservacao  VARCHAR(20)    NOT NULL DEFAULT 'Bom',
    status              VARCHAR(20)    NOT NULL DEFAULT 'Disponivel',
    CONSTRAINT fk_equip_categoria FOREIGN KEY (id_categoria)
        REFERENCES categorias (id_categoria),
    CONSTRAINT ck_equip_valor  CHECK (valor_diaria > 0),
    CONSTRAINT ck_equip_estado CHECK (estado_conservacao IN ('Novo','Bom','Regular','Ruim')),
    CONSTRAINT ck_equip_status CHECK (status IN ('Disponivel','Alugado','Manutencao','Inativo'))
);

/* ---------------------------------------------------------------------
   KITS
   --------------------------------------------------------------------- */
CREATE TABLE kits (
    id_kit        SERIAL         PRIMARY KEY,
    nome          VARCHAR(80)    NOT NULL UNIQUE,
    descricao     VARCHAR(200),
    valor_diaria  NUMERIC(10,2)  NOT NULL,
    disponivel    BOOLEAN        NOT NULL DEFAULT TRUE,
    CONSTRAINT ck_kits_valor CHECK (valor_diaria > 0)
);

/* ---------------------------------------------------------------------
   ITENS_KIT
   --------------------------------------------------------------------- */
CREATE TABLE itens_kit (
    id_item_kit     SERIAL   PRIMARY KEY,
    id_kit          INTEGER  NOT NULL,
    id_equipamento  INTEGER  NOT NULL,
    CONSTRAINT fk_itkit_kit  FOREIGN KEY (id_kit)
        REFERENCES kits (id_kit) ON DELETE CASCADE,
    CONSTRAINT fk_itkit_equip FOREIGN KEY (id_equipamento)
        REFERENCES equipamentos (id_equipamento),
    CONSTRAINT uq_itkit UNIQUE (id_kit, id_equipamento)
);

/* ---------------------------------------------------------------------
   LOCACOES
   --------------------------------------------------------------------- */
CREATE TABLE locacoes (
    id_locacao               SERIAL       PRIMARY KEY,
    id_cliente               INTEGER      NOT NULL,
    data_inicio              DATE         NOT NULL DEFAULT CURRENT_DATE,
    data_prevista_devolucao  DATE         NOT NULL,
    data_devolucao           DATE,
    status                   VARCHAR(20)  NOT NULL DEFAULT 'Ativa',
    CONSTRAINT fk_loc_cliente FOREIGN KEY (id_cliente)
        REFERENCES clientes (id_cliente),
    CONSTRAINT ck_loc_status CHECK (status IN ('Ativa','Concluida','Atrasada','Cancelada')),
    CONSTRAINT ck_loc_prevista CHECK (data_prevista_devolucao >= data_inicio),
    CONSTRAINT ck_loc_devolucao CHECK (data_devolucao IS NULL OR data_devolucao >= data_inicio)
);

/* ---------------------------------------------------------------------
   ITENS_LOCACAO
   --------------------------------------------------------------------- */
CREATE TABLE itens_locacao (
    id_item         SERIAL         PRIMARY KEY,
    id_locacao      INTEGER        NOT NULL,
    id_equipamento  INTEGER,
    id_kit          INTEGER,
    quantidade      INTEGER        NOT NULL DEFAULT 1,
    valor_diaria    NUMERIC(10,2)  NOT NULL,
    CONSTRAINT fk_itloc_locacao FOREIGN KEY (id_locacao)
        REFERENCES locacoes (id_locacao) ON DELETE CASCADE,
    CONSTRAINT fk_itloc_equip FOREIGN KEY (id_equipamento)
        REFERENCES equipamentos (id_equipamento),
    CONSTRAINT fk_itloc_kit FOREIGN KEY (id_kit)
        REFERENCES kits (id_kit),
    CONSTRAINT ck_itloc_qtd   CHECK (quantidade > 0),
    CONSTRAINT ck_itloc_valor CHECK (valor_diaria >= 0),
    CONSTRAINT ck_itloc_equip_ou_kit CHECK (
        (id_equipamento IS NOT NULL AND id_kit IS NULL) OR
        (id_equipamento IS NULL AND id_kit IS NOT NULL)
    )
);

/* ---------------------------------------------------------------------
   PAGAMENTOS
   --------------------------------------------------------------------- */
CREATE TABLE pagamentos (
    id_pagamento     SERIAL         PRIMARY KEY,
    id_locacao       INTEGER        NOT NULL,
    data_pagamento   DATE           NOT NULL DEFAULT CURRENT_DATE,
    valor            NUMERIC(10,2)  NOT NULL,
    forma_pagamento  VARCHAR(30)    NOT NULL,
    status           VARCHAR(20)    NOT NULL DEFAULT 'Pendente',
    CONSTRAINT fk_pag_locacao FOREIGN KEY (id_locacao)
        REFERENCES locacoes (id_locacao),
    CONSTRAINT ck_pag_valor  CHECK (valor > 0),
    CONSTRAINT ck_pag_forma  CHECK (forma_pagamento IN
        ('Pix','Cartao de Credito','Cartao de Debito','Dinheiro','Boleto')),
    CONSTRAINT ck_pag_status CHECK (status IN ('Pago','Pendente','Estornado'))
);

/* Descrições das tabelas também gravadas no próprio banco */
COMMENT ON TABLE clientes      IS 'Cadastro dos clientes que alugam equipamentos';
COMMENT ON TABLE categorias    IS 'Categorias para classificar os equipamentos';
COMMENT ON TABLE equipamentos  IS 'Unidades físicas disponíveis para locação';
COMMENT ON TABLE kits          IS 'Pacotes prontos de equipamentos com diária própria';
COMMENT ON TABLE itens_kit     IS 'Equipamentos que compõem cada kit (relação N:N)';
COMMENT ON TABLE locacoes      IS 'Contratos de locação feitos pelos clientes';
COMMENT ON TABLE itens_locacao IS 'Itens (equipamento avulso ou kit) de cada locação';
COMMENT ON TABLE pagamentos    IS 'Pagamentos realizados em cada locação';


/* =====================================================================
   2. INSERÇÃO DE DADOS (massa de dados)
   ===================================================================== */

INSERT INTO clientes (nome, cpf, telefone, email, instituicao_ensino, data_cadastro) VALUES
('Ana Beatriz Souza',   '11122233301', '31991110001', 'ana.souza@email.com',     'Faculdade Libertas', '2026-08-20'),
('Carlos Eduardo Lima', '11122233302', '31991110002', 'carlos.lima@email.com',   'UFMG',               '2026-08-25'),
('Mariana Alves',       '11122233303', '31991110003', 'mariana.alves@email.com', 'PUC Minas',          '2026-09-02'),
('João Pedro Santos',   '11122233304', '31991110004', 'joao.santos@email.com',   'Faculdade Libertas', '2026-09-10'),
('Fernanda Costa',      '11122233305', '31991110005', 'fernanda.costa@email.com','UNA',                '2026-09-18'),
('Lucas Oliveira',      '11122233306', '31991110006', 'lucas.oliveira@email.com','CEFET-MG',           '2026-09-25'),
('Juliana Ribeiro',     '11122233307', '31991110007', 'juliana.ribeiro@email.com', NULL,               '2026-10-05'),
('Rafael Mendes',       '11122233308', '31991110008', 'rafael.mendes@email.com', 'UFMG',               '2026-10-15');

INSERT INTO categorias (nome, descricao) VALUES
('Notebooks',     'Notebooks para estudo e trabalho'),
('Perifericos',   'Teclados, mouses e webcams'),
('Monitores',     'Monitores de diferentes tamanhos'),
('Desktops',      'Computadores de mesa completos'),
('Tablets',       'Tablets para leitura e anotações'),
('Audio',         'Headsets e fones de ouvido');

INSERT INTO equipamentos (id_categoria, nome, marca, modelo, numero_serie, valor_diaria, estado_conservacao, status) VALUES
(1, 'Notebook Dell Inspiron',       'Dell',     'Inspiron 15',        'DL-INS-0001', 35.00, 'Bom',     'Disponivel'),
(1, 'Notebook Lenovo IdeaPad',      'Lenovo',   'IdeaPad 3',          'LN-IDP-0002', 32.00, 'Bom',     'Alugado'),
(1, 'Notebook Acer Aspire',         'Acer',     'Aspire 5',           'AC-ASP-0003', 33.00, 'Novo',    'Alugado'),
(2, 'Teclado Bluetooth Logitech',   'Logitech', 'K380',               'LG-K380-0004', 6.00, 'Bom',     'Disponivel'),
(2, 'Mouse Sem Fio Logitech',       'Logitech', 'M170',               'LG-M170-0005', 4.00, 'Bom',     'Disponivel'),
(2, 'Teclado Mecanico Redragon',    'Redragon', 'Kumara K552',        'RD-K552-0006', 10.00,'Bom',     'Alugado'),
(2, 'Mouse Gamer Redragon',         'Redragon', 'Cobra M711',         'RD-M711-0007', 8.00, 'Bom',     'Alugado'),
(3, 'Monitor LG 24 polegadas',      'LG',       '24MK430H',           'LG-MON-0008', 15.00, 'Bom',     'Alugado'),
(3, 'Monitor Samsung Odyssey 27',   'Samsung',  'Odyssey G3',         'SM-ODY-0009', 22.00, 'Novo',    'Alugado'),
(4, 'PC Gamer Ryzen 5 RTX 3060',    'Montado',  'Ryzen 5 5600 / RTX 3060', 'PC-GMR-0010', 50.00, 'Novo', 'Alugado'),
(6, 'Headset HyperX Cloud II',      'HyperX',   'Cloud II',           'HX-CLD-0011', 12.00, 'Bom',     'Alugado'),
(2, 'Webcam Logitech Full HD',      'Logitech', 'C920',               'LG-C920-0012', 8.00, 'Regular', 'Manutencao'),
(5, 'Tablet Samsung Galaxy Tab A8', 'Samsung',  'Galaxy Tab A8',      'SM-TAB-0013', 20.00, 'Bom',     'Alugado'),
(2, 'Teclado Bluetooth Multilaser', 'Multilaser','TC-BT',             'ML-TBT-0014',  5.00, 'Bom',     'Alugado');

INSERT INTO kits (nome, descricao, valor_diaria, disponivel) VALUES
('Kit Estudante',        'Notebook + teclado + mouse',                        45.00, TRUE),
('Kit Gamer',            'Computador + monitor + periféricos gamer + headset', 85.00, FALSE),
('Kit Home Office',      'Notebook + monitor + teclado + mouse + webcam',     55.00, FALSE),
('Kit Videoconferência', 'Webcam + headset',                                  17.00, FALSE),
('Kit Mobilidade',       'Tablet + teclado bluetooth',                        24.00, FALSE);

INSERT INTO itens_kit (id_kit, id_equipamento) VALUES
(1, 1), (1, 4), (1, 5),                       -- Kit Estudante
(2, 10), (2, 9), (2, 6), (2, 7), (2, 11),     -- Kit Gamer
(3, 2), (3, 8), (3, 4), (3, 5), (3, 12),      -- Kit Home Office
(4, 12), (4, 11),                             -- Kit Videoconferência
(5, 13), (5, 14);                             -- Kit Mobilidade

INSERT INTO locacoes (id_cliente, data_inicio, data_prevista_devolucao, data_devolucao, status) VALUES
(1, '2026-09-01', '2026-09-08', '2026-09-08', 'Concluida'),
(2, '2026-09-10', '2026-09-17', '2026-09-19', 'Concluida'),
(3, '2026-09-15', '2026-09-22', '2026-09-22', 'Concluida'),
(4, '2026-10-01', '2026-10-15', '2026-10-14', 'Concluida'),
(5, '2026-10-20', '2026-10-27', NULL,         'Atrasada'),
(1, '2026-10-20', '2026-11-03', '2026-11-03', 'Concluida'),
(6, '2026-10-28', '2026-11-11', NULL,         'Ativa'),
(7, '2026-11-01', '2026-11-08', NULL,         'Ativa'),
(8, '2026-11-02', '2026-11-09', NULL,         'Ativa'),
(3, '2026-11-03', '2026-11-06', NULL,         'Cancelada');

-- Cada item é um equipamento avulso (id_equipamento) OU um kit (id_kit)
INSERT INTO itens_locacao (id_locacao, id_equipamento, id_kit, quantidade, valor_diaria) VALUES
(1,  1,    NULL, 1, 35.00),   -- Notebook Dell Inspiron (avulso)
(2,  NULL, 1,    1, 45.00),   -- Kit Estudante
(3,  NULL, 2,    1, 85.00),   -- Kit Gamer
(4,  NULL, 3,    1, 55.00),   -- Kit Home Office
(4,  13,   NULL, 1, 20.00),   -- Tablet (avulso)
(5,  2,    NULL, 1, 32.00),   -- Notebook Lenovo (avulso)
(6,  NULL, 4,    1, 17.00),   -- Kit Videoconferência
(7,  NULL, 2,    1, 85.00),   -- Kit Gamer
(8,  NULL, 5,    1, 24.00),   -- Kit Mobilidade
(9,  3,    NULL, 1, 33.00),   -- Notebook Acer (avulso)
(9,  8,    NULL, 1, 15.00),   -- Monitor LG (avulso)
(10, NULL, 1,    1, 45.00);   -- Kit Estudante (locação cancelada)

INSERT INTO pagamentos (id_locacao, data_pagamento, valor, forma_pagamento, status) VALUES
(1, '2026-09-01', 245.00, 'Pix',              'Pago'),
(2, '2026-09-10', 315.00, 'Pix',              'Pago'),
(2, '2026-09-19',  90.00, 'Cartao de Debito', 'Pago'),
(3, '2026-09-15', 595.00, 'Cartao de Credito','Pago'),
(4, '2026-10-01', 500.00, 'Pix',              'Pago'),
(4, '2026-10-14', 475.00, 'Pix',              'Pago'),
(5, '2026-10-20', 224.00, 'Boleto',           'Pendente'),
(6, '2026-10-20', 238.00, 'Pix',              'Pago'),
(7, '2026-10-28', 595.00, 'Cartao de Credito','Pago'),
(7, '2026-11-04', 595.00, 'Boleto',           'Pendente'),
(8, '2026-11-01', 168.00, 'Dinheiro',         'Pago'),
(9, '2026-11-02', 336.00, 'Cartao de Debito', 'Pago'),
(10,'2026-11-03', 135.00, 'Pix',              'Estornado');


/* =====================================================================
   3. CONSULTAS SQL
   ===================================================================== */

-- JOIN: locações com o nome do cliente e a situação
SELECT l.id_locacao, c.nome AS cliente, l.data_inicio,
       l.data_prevista_devolucao, l.status
FROM locacoes l
JOIN clientes c ON c.id_cliente = l.id_cliente
ORDER BY l.data_inicio, l.id_locacao;

-- JOIN + GROUP BY: quantidade de equipamentos e média da diária por categoria
SELECT cat.nome AS categoria,
       COUNT(e.id_equipamento)      AS qtd_equipamentos,
       ROUND(AVG(e.valor_diaria),2) AS media_diaria
FROM categorias cat
LEFT JOIN equipamentos e ON e.id_categoria = cat.id_categoria
GROUP BY cat.nome
ORDER BY qtd_equipamentos DESC;

-- JOIN + GROUP BY + HAVING: clientes com mais de uma locação
SELECT c.nome, COUNT(l.id_locacao) AS total_locacoes
FROM clientes c
JOIN locacoes l ON l.id_cliente = c.id_cliente
GROUP BY c.nome
HAVING COUNT(l.id_locacao) > 1
ORDER BY total_locacoes DESC;

-- JOIN (3 tabelas) + GROUP BY: composição dos kits e economia frente ao aluguel avulso
SELECT k.nome AS kit,
       COUNT(ik.id_equipamento)  AS qtd_itens,
       SUM(e.valor_diaria)       AS soma_avulsa,
       k.valor_diaria            AS valor_kit,
       SUM(e.valor_diaria) - k.valor_diaria AS economia_por_dia
FROM kits k
JOIN itens_kit ik    ON ik.id_kit = k.id_kit
JOIN equipamentos e  ON e.id_equipamento = ik.id_equipamento
GROUP BY k.id_kit, k.nome, k.valor_diaria
ORDER BY economia_por_dia DESC;

-- GROUP BY + filtro: receita recebida por forma de pagamento (somente pagamentos 'Pago')
SELECT forma_pagamento,
       COUNT(*)   AS qtd_pagamentos,
       SUM(valor) AS total_recebido
FROM pagamentos
WHERE status = 'Pago'
GROUP BY forma_pagamento
ORDER BY total_recebido DESC;

-- Filtro condicional: locações em aberto com devolução prevista já vencida
SELECT l.id_locacao, c.nome AS cliente, c.telefone,
       l.data_prevista_devolucao,
       CURRENT_DATE - l.data_prevista_devolucao AS dias_de_atraso
FROM locacoes l
JOIN clientes c ON c.id_cliente = l.id_cliente
WHERE l.data_devolucao IS NULL
  AND l.status IN ('Ativa','Atrasada')
  AND l.data_prevista_devolucao < CURRENT_DATE;

-- Filtro condicional: equipamentos disponíveis com diária de até R$ 35
SELECT e.nome, e.marca, cat.nome AS categoria, e.valor_diaria
FROM equipamentos e
JOIN categorias cat ON cat.id_categoria = e.id_categoria
WHERE e.status = 'Disponivel' AND e.valor_diaria <= 35
ORDER BY e.valor_diaria DESC;

-- JOIN + GROUP BY + UNION ALL: equipamentos mais alugados (avulsos + dentro de kits)
SELECT e.nome, COUNT(*) AS vezes_alugado
FROM equipamentos e
JOIN (
    SELECT id_locacao, id_equipamento
    FROM itens_locacao
    WHERE id_equipamento IS NOT NULL
    UNION ALL
    SELECT il.id_locacao, ik.id_equipamento
    FROM itens_locacao il
    JOIN itens_kit ik ON ik.id_kit = il.id_kit
) x ON x.id_equipamento = e.id_equipamento
JOIN locacoes l ON l.id_locacao = x.id_locacao
WHERE l.status <> 'Cancelada'
GROUP BY e.nome
ORDER BY vezes_alugado DESC, e.nome
LIMIT 5;

--CTE + JOIN: valor total de cada locação, total pago e saldo em aberto
WITH diaria AS (
    SELECT id_locacao, SUM(quantidade * valor_diaria) AS valor_dia
    FROM itens_locacao
    GROUP BY id_locacao
), pago AS (
    SELECT id_locacao, SUM(valor) AS total_pago
    FROM pagamentos
    WHERE status = 'Pago'
    GROUP BY id_locacao
)
SELECT l.id_locacao, c.nome AS cliente,
       COALESCE(l.data_devolucao, l.data_prevista_devolucao) - l.data_inicio AS dias,
       d.valor_dia * (COALESCE(l.data_devolucao, l.data_prevista_devolucao) - l.data_inicio) AS valor_total,
       COALESCE(p.total_pago, 0) AS total_pago,
       d.valor_dia * (COALESCE(l.data_devolucao, l.data_prevista_devolucao) - l.data_inicio)
         - COALESCE(p.total_pago, 0) AS saldo_em_aberto
FROM locacoes l
JOIN clientes c ON c.id_cliente = l.id_cliente
JOIN diaria d   ON d.id_locacao = l.id_locacao
LEFT JOIN pago p ON p.id_locacao = l.id_locacao
WHERE l.status <> 'Cancelada'
ORDER BY saldo_em_aberto DESC, l.id_locacao;

--GROUP BY: clientes cadastrados por instituição de ensino
SELECT COALESCE(instituicao_ensino, 'Não informada') AS instituicao,
       COUNT(*) AS qtd_clientes
FROM clientes
GROUP BY instituicao_ensino
ORDER BY qtd_clientes DESC, instituicao;



