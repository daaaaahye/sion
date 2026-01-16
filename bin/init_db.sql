CREATE TABLE customers (
    meter_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    usage_amount INT DEFAULT 0,
    overdue_amount INT DEFAULT 0,
    overdue_months INT DEFAULT 0
);

INSERT INTO customers VALUES ('WAT-2026-001', '홍길동', '서울시 관악구', 15, 0, 0);
INSERT INTO customers VALUES ('WAT-2026-002', '김철수', '서울시 강남구', 42, 12500, 2);