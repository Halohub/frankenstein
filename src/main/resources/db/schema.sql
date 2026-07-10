CREATE DATABASE IF NOT EXISTS frankenstein DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Frankenstein application database';
USE frankenstein;

-- ---------------------------------------------------------------------------
-- Admin accounts (back-office)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_admin (
    id              BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    username        VARCHAR(64)  NOT NULL                COMMENT 'Login username, unique',
    password        VARCHAR(128) NOT NULL                COMMENT 'BCrypt password hash',
    nickname        VARCHAR(64)  DEFAULT NULL           COMMENT 'Display name',
    phone           VARCHAR(20)  DEFAULT NULL           COMMENT 'Mobile phone number',
    email           VARCHAR(128) DEFAULT NULL           COMMENT 'Email address',
    status          TINYINT      NOT NULL DEFAULT 1     COMMENT 'Account status: 0=disabled, 1=active',
    last_login_time DATETIME     DEFAULT NULL           COMMENT 'Last successful login time',
    create_time     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted         TINYINT      NOT NULL DEFAULT 0     COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    UNIQUE KEY uk_admin_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Back-office administrator accounts';

-- ---------------------------------------------------------------------------
-- Member accounts (mall / user client)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_member (
    id              BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    username        VARCHAR(64)  NOT NULL                COMMENT 'Login username, unique',
    password        VARCHAR(128) NOT NULL                COMMENT 'BCrypt password hash',
    nickname        VARCHAR(64)  DEFAULT NULL           COMMENT 'Display name',
    phone           VARCHAR(20)  DEFAULT NULL           COMMENT 'Mobile phone number, unique when set',
    email           VARCHAR(128) DEFAULT NULL           COMMENT 'Email address, unique when set',
    vip_level       TINYINT      NOT NULL DEFAULT 0     COMMENT 'VIP level: 0=normal, 1=vip (affects max login devices)',
    status          TINYINT      NOT NULL DEFAULT 1     COMMENT 'Account status: 0=disabled, 1=active',
    register_source VARCHAR(32)  DEFAULT 'web'          COMMENT 'Registration channel, e.g. web, app, h5',
    last_login_time DATETIME     DEFAULT NULL           COMMENT 'Last successful login time',
    create_time     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted         TINYINT      NOT NULL DEFAULT 0     COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    UNIQUE KEY uk_member_username (username),
    UNIQUE KEY uk_member_phone (phone),
    UNIQUE KEY uk_member_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Mall member / end-user accounts';

-- ---------------------------------------------------------------------------
-- Roles (scoped to ADMIN or MEMBER)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_role (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    role_code   VARCHAR(64)  NOT NULL                COMMENT 'Role code, unique, e.g. ADMIN_SUPER',
    role_name   VARCHAR(64)  NOT NULL                COMMENT 'Human-readable role name',
    role_scope  VARCHAR(16)  NOT NULL                COMMENT 'Applicable account scope: ADMIN or MEMBER',
    status      TINYINT      NOT NULL DEFAULT 1     COMMENT 'Role status: 0=disabled, 1=active',
    remark      VARCHAR(255) DEFAULT NULL           COMMENT 'Optional description',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted     TINYINT      NOT NULL DEFAULT 0     COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_code (role_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RBAC roles for admin and member accounts';

-- ---------------------------------------------------------------------------
-- Permissions (menu / button / API)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_permission (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    perm_code   VARCHAR(128) NOT NULL                COMMENT 'Permission code, format scope:module:action',
    perm_name   VARCHAR(64)  NOT NULL                COMMENT 'Default permission name (English fallback)',
    perm_type   VARCHAR(16)  NOT NULL DEFAULT 'API'  COMMENT 'Permission type: MENU, BUTTON, or API',
    parent_id   BIGINT       DEFAULT 0               COMMENT 'Parent permission ID for tree structure, 0=root',
    path        VARCHAR(255) DEFAULT NULL           COMMENT 'Frontend route path for MENU permissions',
    component   VARCHAR(255) DEFAULT NULL           COMMENT 'Vue component path; # layout, ## parent layout',
    icon        VARCHAR(64)  DEFAULT NULL           COMMENT 'Menu icon identifier',
    hidden      TINYINT      NOT NULL DEFAULT 0     COMMENT 'Hide from sidebar: 0=visible, 1=hidden',
    sort        INT          DEFAULT 0               COMMENT 'Display sort order, ascending',
    status      TINYINT      NOT NULL DEFAULT 1     COMMENT 'Permission status: 0=disabled, 1=active',
    api_path    VARCHAR(255) DEFAULT NULL           COMMENT 'Backend API path for API permissions',
    method      VARCHAR(16)  DEFAULT NULL           COMMENT 'HTTP method for API permissions, e.g. GET, POST',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted     TINYINT      NOT NULL DEFAULT 0     COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    UNIQUE KEY uk_perm_code (perm_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RBAC permissions for menus, buttons, and APIs';

-- ---------------------------------------------------------------------------
-- Business i18n messages
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_i18n_message (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    ref_type    VARCHAR(32)  NOT NULL                COMMENT 'Reference type, e.g. PERMISSION',
    ref_id      BIGINT       NOT NULL                COMMENT 'Referenced entity id',
    locale      VARCHAR(16)  NOT NULL                COMMENT 'Language tag: en, zh, ja',
    field_name  VARCHAR(64)  NOT NULL                COMMENT 'Translated field name',
    field_value VARCHAR(512) NOT NULL               COMMENT 'Translated text',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    PRIMARY KEY (id),
    UNIQUE KEY uk_i18n_ref (ref_type, ref_id, locale, field_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Business i18n messages for dynamic content';

-- ---------------------------------------------------------------------------
-- Role-permission mapping
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_role_permission (
    id            BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    role_id       BIGINT NOT NULL                COMMENT 'Foreign key to sys_role.id',
    permission_id BIGINT NOT NULL                COMMENT 'Foreign key to sys_permission.id',
    PRIMARY KEY (id),
    UNIQUE KEY uk_role_perm (role_id, permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Many-to-many mapping between roles and permissions';

-- ---------------------------------------------------------------------------
-- Admin-role mapping
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_admin_role (
    id       BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    admin_id BIGINT NOT NULL                COMMENT 'Foreign key to sys_admin.id',
    role_id  BIGINT NOT NULL                COMMENT 'Foreign key to sys_role.id (role_scope must be ADMIN)',
    PRIMARY KEY (id),
    UNIQUE KEY uk_admin_role (admin_id, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Many-to-many mapping between admin accounts and roles';

-- ---------------------------------------------------------------------------
-- Member-role mapping
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS sys_member_role (
    id        BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    member_id BIGINT NOT NULL                COMMENT 'Foreign key to sys_member.id',
    role_id   BIGINT NOT NULL                COMMENT 'Foreign key to sys_role.id (role_scope must be MEMBER)',
    PRIMARY KEY (id),
    UNIQUE KEY uk_member_role (member_id, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Many-to-many mapping between member accounts and roles';

-- ---------------------------------------------------------------------------
-- Mall: product catalog (category / SPU / SKU)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz_category (
    id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    parent_id   BIGINT       NOT NULL DEFAULT 0      COMMENT 'Parent category id, 0=root',
    name        VARCHAR(64)  NOT NULL                COMMENT 'Category name',
    icon        VARCHAR(128) DEFAULT NULL           COMMENT 'Icon URL or identifier',
    sort        INT          NOT NULL DEFAULT 0      COMMENT 'Display sort order, ascending',
    level       INT          NOT NULL DEFAULT 1      COMMENT 'Tree level starting from 1',
    status      TINYINT      NOT NULL DEFAULT 1      COMMENT '0=disabled, 1=active',
    create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted     TINYINT      NOT NULL DEFAULT 0      COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    KEY idx_category_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Product category tree';

CREATE TABLE IF NOT EXISTS biz_spu (
    id          BIGINT         NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    category_id BIGINT         NOT NULL                COMMENT 'Foreign key to biz_category.id',
    title       VARCHAR(128)   NOT NULL                COMMENT 'Product title',
    subtitle    VARCHAR(255)   DEFAULT NULL            COMMENT 'Product subtitle',
    description TEXT           DEFAULT NULL            COMMENT 'Product description',
    main_image  VARCHAR(512)   DEFAULT NULL            COMMENT 'Main image URL',
    min_price   DECIMAL(12, 2) NOT NULL DEFAULT 0.00   COMMENT 'Minimum SKU price (denormalized)',
    max_price   DECIMAL(12, 2) NOT NULL DEFAULT 0.00   COMMENT 'Maximum SKU price (denormalized)',
    status      TINYINT        NOT NULL DEFAULT 0      COMMENT '0=off shelf, 1=on shelf',
    create_time DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted     TINYINT        NOT NULL DEFAULT 0      COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    KEY idx_spu_category (category_id),
    KEY idx_spu_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Standard Product Unit (SPU)';

CREATE TABLE IF NOT EXISTS biz_sku (
    id          BIGINT         NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    spu_id      BIGINT         NOT NULL                COMMENT 'Foreign key to biz_spu.id',
    sku_code    VARCHAR(64)    NOT NULL                COMMENT 'SKU code, unique',
    spec_json   VARCHAR(512)   DEFAULT NULL            COMMENT 'Spec attributes JSON, e.g. {"color":"black"}',
    price       DECIMAL(12, 2) NOT NULL                COMMENT 'Sale price',
    stock       INT            NOT NULL DEFAULT 0      COMMENT 'Available stock',
    image       VARCHAR(512)   DEFAULT NULL            COMMENT 'SKU image URL',
    status      TINYINT        NOT NULL DEFAULT 1      COMMENT '0=disabled, 1=active',
    create_time DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted     TINYINT        NOT NULL DEFAULT 0      COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    UNIQUE KEY uk_sku_code (sku_code),
    KEY idx_sku_spu (spu_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Stock Keeping Unit (SKU)';

CREATE TABLE IF NOT EXISTS biz_cart_item (
    id          BIGINT   NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    member_id   BIGINT   NOT NULL                COMMENT 'Foreign key to sys_member.id',
    sku_id      BIGINT   NOT NULL                COMMENT 'Foreign key to biz_sku.id',
    quantity    INT      NOT NULL DEFAULT 1      COMMENT 'Quantity in cart',
    selected    TINYINT  NOT NULL DEFAULT 1      COMMENT 'Selected for checkout: 0=no, 1=yes',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    PRIMARY KEY (id),
    UNIQUE KEY uk_cart_member_sku (member_id, sku_id),
    KEY idx_cart_member (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Member shopping cart items';

CREATE TABLE IF NOT EXISTS biz_order (
    id               BIGINT         NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    order_no         VARCHAR(32)    NOT NULL                COMMENT 'Business order number, unique',
    member_id        BIGINT         NOT NULL                COMMENT 'Foreign key to sys_member.id',
    status           VARCHAR(16)    NOT NULL                COMMENT 'PENDING_PAY, PAID, SHIPPED, COMPLETED, CANCELLED',
    source           VARCHAR(16)    NOT NULL                COMMENT 'CART or DIRECT',
    total_amount     DECIMAL(12, 2) NOT NULL DEFAULT 0.00   COMMENT 'Items subtotal',
    freight_amount   DECIMAL(12, 2) NOT NULL DEFAULT 0.00   COMMENT 'Freight amount',
    pay_amount       DECIMAL(12, 2) NOT NULL DEFAULT 0.00   COMMENT 'Amount to pay',
    currency         VARCHAR(8)     NOT NULL DEFAULT 'CNY'  COMMENT 'Currency code',
    receiver_name    VARCHAR(64)    NOT NULL                COMMENT 'Receiver name',
    receiver_phone   VARCHAR(20)    NOT NULL                COMMENT 'Receiver phone',
    receiver_address VARCHAR(512)   NOT NULL                COMMENT 'Receiver address',
    remark           VARCHAR(255)   DEFAULT NULL            COMMENT 'Buyer remark',
    pay_time         DATETIME       DEFAULT NULL            COMMENT 'Payment success time',
    expire_time      DATETIME       DEFAULT NULL            COMMENT 'Payment deadline for PENDING_PAY',
    cancel_time      DATETIME       DEFAULT NULL            COMMENT 'Cancellation time',
    complete_time    DATETIME       DEFAULT NULL            COMMENT 'Order completion time',
    create_time      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted          TINYINT        NOT NULL DEFAULT 0      COMMENT 'Logical delete flag',
    PRIMARY KEY (id),
    UNIQUE KEY uk_order_no (order_no),
    KEY idx_order_member (member_id),
    KEY idx_order_status_expire (status, expire_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Member orders';

CREATE TABLE IF NOT EXISTS biz_order_item (
    id            BIGINT         NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    order_id      BIGINT         NOT NULL                COMMENT 'Foreign key to biz_order.id',
    spu_id        BIGINT         NOT NULL                COMMENT 'SPU id snapshot reference',
    sku_id        BIGINT         NOT NULL                COMMENT 'SKU id snapshot reference',
    product_title VARCHAR(128)   NOT NULL                COMMENT 'Product title snapshot',
    sku_code      VARCHAR(64)    NOT NULL                COMMENT 'SKU code snapshot',
    sku_spec      VARCHAR(512)   DEFAULT NULL            COMMENT 'SKU spec JSON snapshot',
    unit_price    DECIMAL(12, 2) NOT NULL                COMMENT 'Unit price snapshot',
    quantity      INT            NOT NULL                COMMENT 'Quantity',
    subtotal      DECIMAL(12, 2) NOT NULL                COMMENT 'Line subtotal',
    create_time   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    PRIMARY KEY (id),
    KEY idx_order_item_order (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Order line items';

CREATE TABLE IF NOT EXISTS biz_payment (
    id              BIGINT         NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    payment_no      VARCHAR(32)    NOT NULL                COMMENT 'Payment number, unique',
    order_id        BIGINT         NOT NULL                COMMENT 'Foreign key to biz_order.id',
    order_no        VARCHAR(32)    NOT NULL                COMMENT 'Order number snapshot',
    member_id       BIGINT         NOT NULL                COMMENT 'Foreign key to sys_member.id',
    channel         VARCHAR(16)    NOT NULL                COMMENT 'MOCK, ALIPAY, WXPAY, STRIPE',
    amount          DECIMAL(12, 2) NOT NULL                COMMENT 'Payment amount',
    currency        VARCHAR(8)     NOT NULL DEFAULT 'CNY'  COMMENT 'Currency code',
    status          VARCHAR(16)    NOT NULL                COMMENT 'PENDING, SUCCESS, FAILED, CLOSED',
    third_party_no  VARCHAR(64)    DEFAULT NULL            COMMENT 'Third-party transaction id',
    client_payload  VARCHAR(1024)  DEFAULT NULL            COMMENT 'Client payment payload JSON',
    callback_raw    TEXT           DEFAULT NULL            COMMENT 'Callback raw body',
    pay_time        DATETIME       DEFAULT NULL            COMMENT 'Payment success time',
    expire_time     DATETIME       DEFAULT NULL            COMMENT 'Payment expire time',
    create_time     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    PRIMARY KEY (id),
    UNIQUE KEY uk_payment_no (payment_no),
    KEY idx_payment_order (order_id),
    KEY idx_payment_member (member_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Order payments';

-- ---------------------------------------------------------------------------
-- Seed data
-- ---------------------------------------------------------------------------
INSERT IGNORE INTO sys_role (id, role_code, role_name, role_scope, remark) VALUES
(1, 'ADMIN_SUPER', 'Super Admin', 'ADMIN', 'Full admin access'),
(2, 'MEMBER_NORMAL', 'Normal Member', 'MEMBER', 'Default member role'),
(3, 'ADMIN_OPERATOR', 'Operator Admin', 'ADMIN', 'Example admin role: back-office access without system/role management');

INSERT IGNORE INTO sys_permission
    (id, perm_code, perm_name, perm_type, parent_id, path, component, icon, hidden, sort, api_path, method) VALUES
(1,  'admin:auth:info',              'Auth Info',        'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/auth/info',          'GET'),
(2,  'admin:auth:menus',             'Auth Menus',       'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/auth/menus',         'GET'),
(10, 'admin:system',                 'System',           'MENU',   0,  '/system', '#',                       'ep:setting',  0, 10, NULL,                               NULL),
(11, 'admin:system:role',            'Roles',            'MENU',   10, 'role',   'views/system/role/index', 'ep:user',     0, 1,  NULL,                               NULL),
(12, 'admin:system:role:add',        'Add Role',         'BUTTON', 11, NULL,     NULL,                      NULL,          0, 1,  NULL,                               NULL),
(13, 'admin:system:role:edit',       'Edit Role',        'BUTTON', 11, NULL,     NULL,                      NULL,          0, 2,  NULL,                               NULL),
(14, 'admin:system:role:delete',     'Delete Role',      'BUTTON', 11, NULL,     NULL,                      NULL,          0, 3,  NULL,                               NULL),
(20, 'admin:system:role:list',       'List Roles',       'API',    11, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/role',               'GET'),
(21, 'admin:system:role:detail',     'Role Detail',      'API',    11, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/role/*',             'GET'),
(22, 'admin:system:role:create',     'Create Role',      'API',    11, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/role',               'POST'),
(23, 'admin:system:role:update',     'Update Role',      'API',    11, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/role/*',             'PUT'),
(24, 'admin:system:role:delete',     'Delete Role',      'API',    11, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/role/*',             'DELETE'),
(30, 'admin:system:permission:tree', 'Permission Tree',  'API',    11, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/permission/tree',    'GET'),
(15, 'admin:system:admin',           'Admins',           'MENU',   10, 'admin',  'views/system/admin/index','ep:avatar',   0, 2,  NULL,                               NULL),
(16, 'admin:system:admin:add',       'Add Admin',        'BUTTON', 15, NULL,     NULL,                      NULL,          0, 1,  NULL,                               NULL),
(17, 'admin:system:admin:edit',      'Edit Admin',       'BUTTON', 15, NULL,     NULL,                      NULL,          0, 2,  NULL,                               NULL),
(18, 'admin:system:admin:delete',    'Delete Admin',     'BUTTON', 15, NULL,     NULL,                      NULL,          0, 3,  NULL,                               NULL),
(25, 'admin:system:admin:list',      'List Admins',      'API',    15, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/admin/list',         'GET'),
(26, 'admin:system:admin:detail',    'Admin Detail',     'API',    15, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/admin/*',            'GET'),
(27, 'admin:system:admin:create',    'Create Admin',     'API',    15, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/admin',              'POST'),
(28, 'admin:system:admin:update',    'Update Admin',     'API',    15, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/admin/*',            'PUT'),
(29, 'admin:system:admin:remove',    'Remove Admin',     'API',    15, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/admin/*',            'DELETE'),
(40, 'admin:member',                 'Members',          'MENU',   0,  '/member', '#',                       'ep:user-filled', 0, 20, NULL,                            NULL),
(41, 'admin:member:list',            'Member List',      'MENU',   40, 'list',   'views/member/list/index', 'ep:list',       0, 1,  NULL,                               NULL),
(42, 'admin:member:view',            'View Member',      'BUTTON', 41, NULL,     NULL,                      NULL,          0, 1,  NULL,                               NULL),
(43, 'admin:member:add',             'Add Member',       'BUTTON', 41, NULL,     NULL,                      NULL,          0, 2,  NULL,                               NULL),
(44, 'admin:member:edit',            'Edit Member',      'BUTTON', 41, NULL,     NULL,                      NULL,          0, 3,  NULL,                               NULL),
(45, 'admin:member:delete',          'Delete Member',    'BUTTON', 41, NULL,     NULL,                      NULL,          0, 4,  NULL,                               NULL),
(50, 'admin:member:query',           'Query Members',    'API',    41, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/member/list',        'GET'),
(51, 'admin:member:detail',          'Member Detail',    'API',    41, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/member/*',           'GET'),
(52, 'admin:member:create',          'Create Member',    'API',    41, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/member',             'POST'),
(53, 'admin:member:update',          'Update Member',    'API',    41, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/member/*',           'PUT'),
(54, 'admin:member:remove',          'Remove Member',    'API',    41, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/member/*',           'DELETE'),
(55, 'admin:member:promote',         'Promote Member',   'API',    41, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/member/*/promote',   'POST'),
(3,  'member:auth:info',             'Member Auth Info', 'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/auth/info',           'GET'),
(4,  'member:order:view',            'View Orders',      'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/order/list',          'GET'),
(14, 'member:order:detail',          'Order Detail',     'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/order/*',             'GET'),
(15, 'member:order:create',          'Create Order',     'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/order',               'POST'),
(16, 'member:order:cancel',          'Cancel Order',     'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/order/*/cancel',      'POST'),
(17, 'member:payment:pay',           'Pay Order',        'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/payment/*',           'POST'),
(5,  'member:product:category:tree', 'Category Tree',    'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/category/tree',       'GET'),
(6,  'member:product:spu:list',       'SPU List',         'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/product/spu/list',    'GET'),
(7,  'member:product:spu:detail',     'SPU Detail',       'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/product/spu/*',       'GET'),
(8,  'member:product:sku:detail',     'SKU Detail',       'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/product/sku/*',       'GET'),
(9,  'member:cart:view',              'View Cart',        'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/list',           'GET'),
(10, 'member:cart:add',               'Add Cart Item',    'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/item',           'POST'),
(11, 'member:cart:update',            'Update Cart Item', 'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/item/*',         'PUT'),
(12, 'member:cart:remove',            'Remove Cart Item', 'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/item/*',         'DELETE'),
(13, 'member:cart:select',            'Select Cart Items','API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/select',         'PUT'),
(60, 'admin:product',                 'Products',         'MENU',   0,  '/product', '#',                     'ep:goods',    0, 30, NULL,                               NULL),
(61, 'admin:product:category',        'Categories',       'MENU',   60, 'category', 'views/product/category/index', 'ep:menu', 0, 1, NULL,                          NULL),
(62, 'admin:product:spu',             'SPU List',         'MENU',   60, 'spu',    'views/product/spu/index', 'ep:goods-filled', 0, 2, NULL,                        NULL),
(63, 'admin:product:category:tree',   'Category Tree',    'API',    61, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/category/tree',      'GET'),
(64, 'admin:product:category:create', 'Create Category',  'API',    61, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/category',             'POST'),
(65, 'admin:product:category:update', 'Update Category',  'API',    61, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/category/*',         'PUT'),
(66, 'admin:product:category:remove', 'Remove Category',  'API',    61, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/category/*',         'DELETE'),
(67, 'admin:product:spu:list',       'List SPU',         'API',    62, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/product/spu/list',   'GET'),
(68, 'admin:product:spu:detail',     'SPU Detail',       'API',    62, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/product/spu/*',      'GET'),
(69, 'admin:product:spu:create',     'Create SPU',       'API',    62, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/product/spu',        'POST'),
(70, 'admin:product:spu:update',     'Update SPU',       'API',    62, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/product/spu/*',      'PUT'),
(71, 'admin:product:spu:remove',     'Remove SPU',       'API',    62, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/product/spu/*',      'DELETE'),
(72, 'admin:product:spu:status',     'Update SPU Status','API',   62, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/product/spu/*/status','PUT');

INSERT IGNORE INTO sys_i18n_message (ref_type, ref_id, locale, field_name, field_value) VALUES
('PERMISSION', 10, 'zh', 'perm_name', '系统管理'),
('PERMISSION', 10, 'ja', 'perm_name', 'システム'),
('PERMISSION', 11, 'zh', 'perm_name', '角色管理'),
('PERMISSION', 11, 'ja', 'perm_name', 'ロール管理'),
('PERMISSION', 15, 'zh', 'perm_name', '管理员'),
('PERMISSION', 15, 'ja', 'perm_name', '管理者'),
('PERMISSION', 40, 'zh', 'perm_name', '会员管理'),
('PERMISSION', 40, 'ja', 'perm_name', '会員管理'),
('PERMISSION', 41, 'zh', 'perm_name', '会员列表'),
('PERMISSION', 41, 'ja', 'perm_name', '会員一覧'),
('PERMISSION', 60, 'zh', 'perm_name', '商品管理'),
('PERMISSION', 60, 'ja', 'perm_name', '商品管理'),
('PERMISSION', 61, 'zh', 'perm_name', '分类管理'),
('PERMISSION', 61, 'ja', 'perm_name', 'カテゴリ管理'),
('PERMISSION', 62, 'zh', 'perm_name', '商品列表'),
('PERMISSION', 62, 'ja', 'perm_name', '商品一覧');

INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT 1, id FROM sys_permission WHERE perm_code LIKE 'admin:%';

INSERT IGNORE INTO sys_role_permission (role_id, permission_id)
SELECT 2, id FROM sys_permission WHERE perm_code LIKE 'member:%';

-- ADMIN_OPERATOR: auth + member CRU (no delete, no promote)
INSERT IGNORE INTO sys_role_permission (role_id, permission_id) VALUES
(3, 1),
(3, 2),
(3, 40),
(3, 41),
(3, 42),
(3, 43),
(3, 44),
(3, 50),
(3, 51),
(3, 52),
(3, 53);


INSERT IGNORE INTO sys_admin (id, username, password, nickname, status) VALUES
(1, 'admin', '$2a$10$DRFSjoDz9NXMt8RQJlvCD.YVRZNmFPWMVzL3NkYKREXbmCHz9TovW', 'Super Admin', 1);

INSERT IGNORE INTO sys_admin_role (admin_id, role_id) VALUES (1, 1);


INSERT IGNORE INTO sys_admin (id, username, password, nickname, status) VALUES
(2, 'operator', '$2a$10$DRFSjoDz9NXMt8RQJlvCD.YVRZNmFPWMVzL3NkYKREXbmCHz9TovW', 'Operator Admin', 1);

INSERT IGNORE INTO sys_admin_role (admin_id, role_id) VALUES (2, 3);
