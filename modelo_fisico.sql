-- ============================================================
-- PROJETO BYTEBANK: MODELO FÍSICO DO BANCO DE DADOS (SQL ANSI / PostgreSQL)
-- ============================================================

-- 1. CRIAÇÃO DAS TABELAS (DDL)

CREATE TABLE clientes (
    id_cliente INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cpf VARCHAR(11) NOT NULL UNIQUE,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    telefone VARCHAR(20),
    data_nascimento DATE NOT NULL,
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE agencias (
    id_agencia INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_agencia VARCHAR(10) NOT NULL UNIQUE,
    nome_agencia VARCHAR(50) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    uf CHAR(2) NOT NULL
);

CREATE TABLE contas (
    id_conta INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero_conta VARCHAR(20) NOT NULL UNIQUE,
    id_cliente INT NOT NULL,
    id_agencia INT NOT NULL,
    tipo_conta VARCHAR(20) NOT NULL CHECK (tipo_conta IN ('CORRENTE', 'POUPANCA', 'INVESTIMENTO')),
    saldo DECIMAL(15, 2) NOT NULL DEFAULT 0.00 CHECK (saldo >= 0),
    status_conta VARCHAR(20) DEFAULT 'ATIVO' CHECK (status_conta IN ('ATIVO', 'BLOQUEADO', 'ENCERRADO')),
    data_abertura DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_contas_cliente FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente) ON DELETE RESTRICT,
    CONSTRAINT fk_contas_agencia FOREIGN KEY (id_agencia) REFERENCES agencias(id_agencia) ON DELETE RESTRICT
);

CREATE TABLE tipos_transacao (
    id_tipo_transacao INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome_transacao VARCHAR(50) NOT NULL UNIQUE,
    natureza VARCHAR(10) NOT NULL CHECK (natureza IN ('CREDITO', 'DEBITO'))
);

CREATE TABLE transacoes (
    id_transacao BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_conta_origem INT NOT NULL,
    id_conta_destino INT, -- Pode ser NULL para saques ou pagamentos externos
    id_tipo_transacao INT NOT NULL,
    valor DECIMAL(15, 2) NOT NULL CHECK (valor > 0),
    data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    descricao VARCHAR(255),
    CONSTRAINT fk_transacoes_conta_origem FOREIGN KEY (id_conta_origem) REFERENCES contas(id_conta),
    CONSTRAINT fk_transacoes_conta_destino FOREIGN KEY (id_conta_destino) REFERENCES contas(id_conta),
    CONSTRAINT fk_transacoes_tipo FOREIGN KEY (id_tipo_transacao) REFERENCES tipos_transacao(id_tipo_transacao)
);

-- 2. CRIAÇÃO DE ÍNDICES PARA OTIMIZAÇÃO DE DESEMPENHO E CONSULTAS ANALÍTICAS

CREATE INDEX idx_contas_cliente ON contas(id_cliente);
CREATE INDEX idx_transacoes_origem_data ON transacoes(id_conta_origem, data_hora);
CREATE INDEX idx_transacoes_destino_data ON transacoes(id_conta_destino, data_hora);
CREATE INDEX idx_transacoes_tipo ON transacoes(id_tipo_transacao);

-- 3. POVOAMENTO DE DADOS INICIAIS (DML)

INSERT INTO agencias (numero_agencia, nome_agencia, cidade, uf) VALUES
('0001', 'Agência Central', 'São Paulo', 'SP'),
('0002', 'Agência Paulista', 'São Paulo', 'SP');

INSERT INTO tipos_transacao (nome_transacao, natureza) VALUES
('PIX_ENVIADO', 'DEBITO'),
('PIX_RECEBIDO', 'CREDITO'),
('SAQUE', 'DEBITO'),
('DEPOSITO', 'CREDITO'),
('COMPRA_DEBITO', 'DEBITO');

INSERT INTO clientes (cpf, nome, email, telefone, data_nascimento) VALUES
('12345678901', 'Ana Silva', 'ana.silva@email.com', '11987654321', '1990-05-15'),
('98765432100', 'Carlos Oliveira', 'carlos.o@email.com', '11912345678', '1985-10-20');

INSERT INTO contas (numero_conta, id_cliente, id_agencia, tipo_conta, saldo, data_abertura) VALUES
('10001-2', 1, 1, 'CORRENTE', 2500.00, '2023-01-10'),
('20002-3', 2, 2, 'CORRENTE', 5000.00, '2023-02-15');

INSERT INTO transacoes (id_conta_origem, id_conta_destino, id_tipo_transacao, valor, descricao) VALUES
(1, 2, 1, 150.00, 'Pagamento PIX serviços'),
(2, NULL, 3, 200.00, 'Saque caixa eletrônico');

-- 4. CONSULTA DE EXEMPLO: ANÁLISE DE COMPORTAMENTO E VOLUME DE TRANSAÇÕES

SELECT 
    c.id_cliente,
    c.nome,
    ct.numero_conta,
    tt.nome_transacao,
    COUNT(t.id_transacao) AS quantidade_operacoes,
    SUM(t.valor) AS volume_total
FROM clientes c
JOIN contas ct ON c.id_cliente = ct.id_cliente
JOIN transacoes t ON ct.id_conta = t.id_conta_origem
JOIN tipos_transacao tt ON t.id_tipo_transacao = tt.id_tipo_transacao
GROUP BY c.id_cliente, c.nome, ct.numero_conta, tt.nome_transacao
ORDER BY volume_total DESC;
