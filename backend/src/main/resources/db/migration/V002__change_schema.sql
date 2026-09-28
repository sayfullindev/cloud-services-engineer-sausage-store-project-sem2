ALTER TABLE orders
ADD COLUMN date_created DATE DEFAULT CURRENT_DATE;

ALTER TABLE orders  
ADD PRIMARY KEY (id);

ALTER TABLE product
ADD COLUMN price DOUBLE PRECISION;
ALTER TABLE product
ADD PRIMARY KEY (id);

ALTER TABLE order_product 
ADD PRIMARY KEY (order_id, product_id);

ALTER TABLE order_product 
ADD FOREIGN KEY (order_id)   REFERENCES orders (id);

ALTER TABLE order_product 
ADD FOREIGN KEY (product_id) REFERENCES product (id);

DROP TABLE product_info;
DROP TABLE orders_date