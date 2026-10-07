# Modelo Físico da Base de Dados — Bytebank

Este documento descreve a estrutura física da base de dados do projeto **Bytebank**. O modelo foi projetado para assegurar a integridade relacional, otimizar a extração de métricas de comportamento financeiro e permitir consultas de elevado desempenho.

---

## 1. Visão Geral da Arquitetura

A base de dados é composta por **5 tabelas principais**:

1. **`clientes`**: Armazena as informações cadastrais dos utilizadores.
2. **`agencias`**: Regista as agências bancárias da instituição.
3. **`contas`**: Associa os clientes e agências a produtos bancários (Corrente, Poupança, Investimento).
4. **`tipos_transacao`**: Catálogo que define a natureza de cada operação (Crédito ou Débito).
5. **`transacoes`**: Histórico detalhado de movimentações financeiras executadas na plataforma.

---

## 2. Estrutura das Tabelas

### 2.1. Tabela `clientes`
Armazena a informação dos clientes do banco.

| Coluna | Tipo de Dado | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_cliente` | `INT` | `PRIMARY KEY`, `IDENTITY` | Identificador único do cliente. |
| `cpf` | `VARCHAR(11)` | `NOT NULL`, `UNIQUE` | Documento de identificação (apenas dígitos). |
| `nome` | `VARCHAR(100)` | `NOT NULL` | Nome completo do cliente. |
| `email` | `VARCHAR(100)` | `NOT NULL`, `UNIQUE` | Correio eletrónico do cliente. |
| `telefone` | `VARCHAR(20)` | Nulo permitido | Número de contacto telefónico. |
| `data_nascimento` | `DATE` | `NOT NULL` | Data de nascimento do cliente. |
| `data_cadastro` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP` | Data e hora do registo no sistema. |

---

### 2.2. Tabela `agencias`
Contém os dados das unidades de atendimento.

| Coluna | Tipo de Dado | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_agencia` | `INT` | `PRIMARY KEY`, `IDENTITY` | Identificador único da agência. |
| `numero_agencia` | `VARCHAR(10)` | `NOT NULL`, `UNIQUE` | Código identificador da agência. |
| `nome_agencia` | `VARCHAR(50)` | `NOT NULL` | Nome da agência. |
| `cidade` | `VARCHAR(50)` | `NOT NULL` | Cidade onde se localiza a agência. |
| `uf` | `CHAR(2)` | `NOT NULL` | Sigla da unidade federativa / estado. |

---

### 2.3. Tabela `contas`
Regista as contas bancárias associadas aos clientes.

| Coluna | Tipo de Dado | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_conta` | `INT` | `PRIMARY KEY`, `IDENTITY` | Identificador único da conta. |
| `numero_conta` | `VARCHAR(20)` | `NOT NULL`, `UNIQUE` | Número oficial da conta bancária. |
| `id_cliente` | `INT` | `FOREIGN KEY` (`clientes`) | Referência ao cliente titular da conta. |
| `id_agencia` | `INT` | `FOREIGN KEY` (`agencias`) | Referência à agência associada. |
| `tipo_conta` | `VARCHAR(20)` | `CHECK` (`CORRENTE`, `POUPANCA`, `INVESTIMENTO`) | Modalidade da conta bancária. |
| `saldo` | `DECIMAL(15,2)` | `CHECK (saldo >= 0)`, `DEFAULT 0.00` | Saldo disponível atual. |
| `status_conta` | `VARCHAR(20)` | `CHECK` (`ATIVO`, `BLOQUEADO`, `ENCERRADO`) | Estado de funcionamento da conta. |
| `data_abertura` | `DATE` | `DEFAULT CURRENT_DATE` | Data em que a conta foi aberta. |

---

### 2.4. Tabela `tipos_transacao`
Catálogo com os tipos de movimentações financeiras permitidas.

| Coluna | Tipo de Dado | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_tipo_transacao` | `INT` | `PRIMARY KEY`, `IDENTITY` | Identificador do tipo de transação. |
| `nome_transacao` | `VARCHAR(50)` | `NOT NULL`, `UNIQUE` | Denominação da operação (ex.: PIX_ENVIADO). |
| `natureza` | `VARCHAR(10)` | `CHECK` (`CREDITO`, `DEBITO`) | Classificação do impacto no saldo. |

---

### 2.5. Tabela `transacoes`
Armazena os registos individuais de cada operação financeira.

| Coluna | Tipo de Dado | Restrições | Descrição |
| :--- | :--- | :--- | :--- |
| `id_transacao` | `BIGINT` | `PRIMARY KEY`, `IDENTITY` | Identificador único da transação. |
| `id_conta_origem` | `INT` | `FOREIGN KEY` (`contas`) | Conta debitada ou pagadora. |
| `id_conta_destino` | `INT` | `FOREIGN KEY` (`contas`), Nulo permitido | Conta creditada (nula em saques/pagamentos externos). |
| `id_tipo_transacao` | `INT` | `FOREIGN KEY` (`tipos_transacao`) | Tipo da operação efetuada. |
| `valor` | `DECIMAL(15,2)` | `CHECK (valor > 0)` | Montante transacionado. |
| `data_hora` | `TIMESTAMP` | `DEFAULT CURRENT_TIMESTAMP` | Data e hora exatas da operação. |
| `descricao` | `VARCHAR(255)` | Nulo permitido | Informação adicional ou nota descritiva. |

---

## 3. Relacionamentos do Modelo

* **`clientes` (1) ── (N) `contas`**: Um cliente pode ser titular de uma ou mais contas bancárias.
* **`agencias` (1) ── (N) `contas`**: Uma agência pode albergar múltiplas contas bancárias.
* **`contas` (1) ── (N) `transacoes` (Origem/Destino)**: Uma conta pode atuar como origem ou destino em múltiplos registos de transação.
* **`tipos_transacao` (1) ── (N) `transacoes`**: Cada transação está vinculada a uma categoria predefinida.

---

## 4. Otimização e Índices

Para garantir rapidez em análises de grandes volumes de dados (como hábitos de consumo e volumes transacionados), foram definidos os seguintes índices:

* **`idx_contas_cliente`**: Acelera a consulta de todas as contas pertencentes a um cliente.
* **`idx_transacoes_origem_data`**: Otimiza a extração de extratos por intervalo de tempo na conta pagadora.
* **`idx_transacoes_destino_data`**: Agiliza a consulta de recebimentos e entradas por período.
* **`idx_transacoes_tipo`**: Otimiza a agregação de relatórios por modalidade de transação (ex.: total em PIX vs. Saques).

---

## 5. Como Executar o Script

1. Utilize um Sistema Gestor de Bases de Dados (SGBD) compatível com ANSI SQL / PostgreSQL (versão 12 ou superior).
2. Abra a consola de comandos ou a sua ferramenta gráfica preferida (ex.: pgAdmin, DBeaver).
3. Execute o script SQL para criar as tabelas, restrições, índices e inserir os dados de teste.
