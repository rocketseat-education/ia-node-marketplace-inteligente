CREATE EXTENSION IF NOT EXISTS vector;

DROP TABLE IF EXISTS carts CASCADE;
DROP TABLE IF EXISTS cart_items CASCADE;
DROP TABLE IF EXISTS stores CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS chat_sessions CASCADE;
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_messages_actions CASCADE;

CREATE TABLE stores (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price INTEGER NOT NULL,
    store_id INTEGER REFERENCES stores(id),
    embedding VECTOR(1536) -- Adjust the dimension based on your embedding model
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chat_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chat_messages (
    id SERIAL PRIMARY KEY,
    chat_session_id INTEGER REFERENCES chat_sessions(id),
    content TEXT NOT NULL,
    sender VARCHAR(50) NOT NULL CHECK (sender in ('user', 'assistant')),
    openai_message_id VARCHAR(100) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message_type VARCHAR(50) NOT NULL CHECK (message_type in ('text', 'suggest_carts_result')) DEFAULT 'text'
);

CREATE TABLE chat_messages_actions (
    id SERIAL PRIMARY KEY,
    chat_message_id INTEGER REFERENCES chat_messages(id),
    action_type VARCHAR(50) NOT NULL CHECK (action_type IN ('suggest_carts')),
    payload JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    confirmed_at TIMESTAMP DEFAULT NULL,
    executed_at TIMESTAMP DEFAULT NULL,
    CONSTRAINT unique_chat_message_action UNIQUE (chat_message_id, action_type)
);

CREATE TABLE carts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    store_id INTEGER REFERENCES stores(id),
    active BOOLEAN DEFAULT TRUE,
    score INTEGER DEFAULT NULL,
    suggested_by_message_id INTEGER REFERENCES chat_messages(id)
);

CREATE TABLE cart_items (
    id SERIAL PRIMARY KEY,
    cart_id INTEGER REFERENCES carts(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_cart_product UNIQUE (cart_id, product_id)
);

-- Usuários
INSERT INTO users (name, email, password) VALUES
  ('John Doe', 'johndoe@email.com', 'dummyhash');

-- Lojas
INSERT INTO stores (name) VALUES
  ('Supermercado Central'),
  ('Mercado Econômico'),
  ('SuperShop Express');

-- Produtos
INSERT INTO products (name, price, store_id) VALUES
-- Supermercado Central (Loja 1)
('Feijão preto - 1kg', 799, 1),
('Arroz branco - 1kg', 599, 1),
('Farinha de mandioca - 500g', 425, 1),
('Linguiça calabresa - 500g', 1190, 1),
('Costelinha suína - 1kg', 1890, 1),
('Macarrão espaguete - 500g', 399, 1),
('Peito de frango - 1kg', 1290, 1),
('Creme de leite - 200g', 299, 1),
('Queijo mussarela - 200g', 690, 1),
('Cenoura - 1kg', 449, 1),
('Ovos - dúzia', 999, 1),
('Açúcar refinado - 1kg', 549, 1),
('Chocolate em pó - 200g', 679, 1),
('Fermento químico - 100g', 299, 1),
('Óleo de soja - 900ml', 649, 1),

-- Mercado Econômico (Loja 2)
('Feijão preto - 1kg', 749, 2),
('Arroz branco - 1kg', 579, 2),
('Linguiça calabresa - 500g', 1090, 2),
('Costelinha suína - 1kg', 1790, 2),
('Macarrão espaguete - 500g', 419, 2),
('Peito de frango - 1kg', 1240, 2),
('Creme de leite - 200g', 289, 2),
('Cenoura - 1kg', 429, 2),
('Ovos - dúzia', 959, 2),
('Chocolate em pó - 200g', 659, 2),
('Fermento químico - 100g', 289, 2),

-- SuperShop Express (Loja 3)
('Farinha de mandioca - 500g', 399, 3),
('Linguiça calabresa - 500g', 1150, 3),
('Peito de frango - 1kg', 1350, 3),
('Creme de leite - 200g', 319, 3),
('Queijo mussarela - 200g', 729, 3),
('Cenoura - 1kg', 469, 3),
('Ovos - dúzia', 1020, 3),
('Açúcar refinado - 1kg', 569, 3),
('Chocolate em pó - 200g', 699, 3),
('Fermento químico - 100g', 319, 3);
