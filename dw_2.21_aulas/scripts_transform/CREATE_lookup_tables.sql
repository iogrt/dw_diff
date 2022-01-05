CREATE TABLE t_lookup_calories(
  min_calories_100g NUMBER(4),
  max_calories_100g NUMBER(4),
  type VARCHAR2(100),
  description VARCHAR2(100),
  CONSTRAINT pk_lookupcalories_type PRIMARY KEY(type)
);


CREATE TABLE t_lookup_pack_dimensions(
  pack_type VARCHAR2(20),
  has_dimensions CHAR,
  CONSTRAINT pk_lookuppackdim_packtype PRIMARY KEY(pack_type)
);


CREATE TABLE t_lookup_brands(
  brand_wrong VARCHAR2(30),
  brand_transformed VARCHAR2(30),
  CONSTRAINT pk_lookupBrands PRIMARY KEY (brand_wrong, brand_transformed)
);




