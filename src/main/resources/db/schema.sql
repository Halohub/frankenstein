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
-- Uploaded file metadata (standalone file module)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz_file (
    id              BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    original_name   VARCHAR(255) NOT NULL                COMMENT 'Original filename',
    object_key      VARCHAR(512) NOT NULL                COMMENT 'OSS object key',
    url             VARCHAR(1024) NOT NULL               COMMENT 'Last known access URL',
    mime_type       VARCHAR(128) DEFAULT NULL           COMMENT 'MIME type',
    size_bytes      BIGINT       NOT NULL DEFAULT 0      COMMENT 'File size in bytes',
    provider        VARCHAR(16)  NOT NULL                COMMENT 'ALIYUN or QINIU',
    biz_type        VARCHAR(32)  DEFAULT NULL            COMMENT 'Optional business category',
    create_time     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    deleted         TINYINT      NOT NULL DEFAULT 0     COMMENT 'Logical delete flag: 0=not deleted, 1=deleted',
    PRIMARY KEY (id),
    KEY idx_file_provider (provider),
    KEY idx_file_biz_type (biz_type),
    KEY idx_file_original_name (original_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Uploaded file metadata';

-- ---------------------------------------------------------------------------
-- IM: member × customer-service sessions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS biz_chat_session (
    id                 BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    member_id          BIGINT       NOT NULL                COMMENT 'Member id (sys_member.id)',
    admin_id           BIGINT       DEFAULT NULL            COMMENT 'Assigned admin id, null until first reply',
    status             VARCHAR(16)  NOT NULL DEFAULT 'OPEN' COMMENT 'OPEN or CLOSED',
    last_message       VARCHAR(512) DEFAULT NULL            COMMENT 'Last message preview',
    last_msg_type      VARCHAR(16)  DEFAULT NULL            COMMENT 'TEXT or IMAGE',
    last_message_time  DATETIME     DEFAULT NULL            COMMENT 'Last message time',
    member_unread      INT          NOT NULL DEFAULT 0      COMMENT 'Unread count for member',
    admin_unread       INT          NOT NULL DEFAULT 0      COMMENT 'Unread count for admin desk',
    create_time        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    update_time        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record last update time',
    PRIMARY KEY (id),
    KEY idx_chat_session_member (member_id, status),
    KEY idx_chat_session_admin (admin_id, status),
    KEY idx_chat_session_last_time (last_message_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM sessions between member and customer service';

CREATE TABLE IF NOT EXISTS biz_chat_message (
    id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    session_id   BIGINT       NOT NULL                COMMENT 'biz_chat_session.id',
    sender_type  VARCHAR(16)  NOT NULL                COMMENT 'MEMBER or ADMIN',
    sender_id    BIGINT       NOT NULL                COMMENT 'Sender account id',
    msg_type     VARCHAR(16)  NOT NULL DEFAULT 'TEXT' COMMENT 'TEXT or IMAGE',
    content      VARCHAR(2048) NOT NULL               COMMENT 'Text body or image URL',
    read_flag    TINYINT      NOT NULL DEFAULT 0      COMMENT '0=unread by peer, 1=read',
    create_time  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation time',
    PRIMARY KEY (id),
    KEY idx_chat_msg_session (session_id, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='IM messages';

-- ---------------------------------------------------------------------------
-- Seed data
-- ---------------------------------------------------------------------------
INSERT INTO sys_role (id, role_code, role_name, role_scope, remark) VALUES
(1, 'ADMIN_SUPER', 'Super Admin', 'ADMIN', 'Full admin access'),
(2, 'MEMBER_NORMAL', 'Normal Member', 'MEMBER', 'Default member role'),
(3, 'ADMIN_OPERATOR', 'Operator Admin', 'ADMIN', 'Example admin role: back-office access without system/role management');

INSERT INTO sys_permission
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
(91, 'member:order:detail',          'Order Detail',     'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/order/*',             'GET'),
(92, 'member:order:create',          'Create Order',     'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/order',               'POST'),
(93, 'member:order:cancel',          'Cancel Order',     'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/order/*/cancel',      'POST'),
(94, 'member:payment:pay',           'Pay Order',        'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/payment/*',           'POST'),
(5,  'member:product:category:tree', 'Category Tree',    'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/category/tree',       'GET'),
(6,  'member:product:spu:list',       'SPU List',         'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/product/spu/list',    'GET'),
(7,  'member:product:spu:detail',     'SPU Detail',       'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/product/spu/*',       'GET'),
(8,  'member:product:sku:detail',     'SKU Detail',       'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/product/sku/*',       'GET'),
(9,  'member:cart:view',              'View Cart',        'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/list',           'GET'),
(87, 'member:cart:add',               'Add Cart Item',    'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/item',           'POST'),
(88, 'member:cart:update',            'Update Cart Item', 'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/item/*',         'PUT'),
(89, 'member:cart:remove',            'Remove Cart Item', 'API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/item/*',         'DELETE'),
(90, 'member:cart:select',            'Select Cart Items','API',    0,  NULL,     NULL,                      NULL,          0, 0,  '/user/api_v1/cart/select',         'PUT'),
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
(72, 'admin:product:spu:status',     'Update SPU Status','API',   62, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/product/spu/*/status','PUT'),
(73, 'admin:order',                  'Orders',           'MENU',   0,  '/order', '#',                     'ep:document', 0, 40, NULL,                               NULL),
(74, 'admin:order:list',             'Order List',       'MENU',   73, 'list',   'views/order/list/index', 'ep:list',     0, 1,  NULL,                               NULL),
(75, 'admin:order:view',             'View Order',       'BUTTON', 74, NULL,     NULL,                      NULL,          0, 1,  NULL,                               NULL),
(76, 'admin:order:query',            'Query Orders',     'API',    74, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/order/list',         'GET'),
(77, 'admin:order:detail',           'Order Detail',     'API',    74, NULL,     NULL,                      NULL,          0, 0,  '/admin/api_v1/order/*',            'GET');

INSERT INTO sys_i18n_message (ref_type, ref_id, locale, field_name, field_value) VALUES
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
('PERMISSION', 62, 'ja', 'perm_name', '商品一覧'),
('PERMISSION', 73, 'zh', 'perm_name', '订单管理'),
('PERMISSION', 73, 'ja', 'perm_name', '注文管理'),
('PERMISSION', 74, 'zh', 'perm_name', '订单列表'),
('PERMISSION', 74, 'ja', 'perm_name', '注文一覧');

INSERT INTO sys_role_permission (role_id, permission_id)
SELECT 1, id FROM sys_permission WHERE perm_code LIKE 'admin:%';

INSERT INTO sys_role_permission (role_id, permission_id)
SELECT 2, id FROM sys_permission WHERE perm_code LIKE 'member:%';

-- ADMIN_OPERATOR: auth + member CRU (no delete, no promote)
INSERT INTO sys_role_permission (role_id, permission_id) VALUES
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


INSERT INTO sys_admin (id, username, password, nickname, status) VALUES
(1, 'admin', '$2a$10$DRFSjoDz9NXMt8RQJlvCD.YVRZNmFPWMVzL3NkYKREXbmCHz9TovW', 'Super Admin', 1);

INSERT INTO sys_admin_role (admin_id, role_id) VALUES (1, 1);


INSERT INTO sys_admin (id, username, password, nickname, status) VALUES
(2, 'operator', '$2a$10$DRFSjoDz9NXMt8RQJlvCD.YVRZNmFPWMVzL3NkYKREXbmCHz9TovW', 'Operator Admin', 1);

INSERT INTO sys_admin_role (admin_id, role_id) VALUES (2, 3);

-- ---------------------------------------------------------------------------
-- Demo product catalog seed data (image URLs from Unsplash CDN)
-- ---------------------------------------------------------------------------

INSERT INTO biz_category (id, parent_id, name, icon, sort, level, status) VALUES
(100,   0, '服装',   'https://images.unsplash.com/photo-1445205170230-053b83016050?w=64&h=64&fit=crop',  1, 1, 1),
(101, 100, '男装',   NULL, 1, 2, 1),
(102, 100, '女装',   NULL, 2, 2, 1),
(103,   0, '鞋帽',   'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=64&h=64&fit=crop',  2, 1, 1),
(104, 103, '运动鞋', NULL, 1, 2, 1),
(105, 103, '休闲鞋', NULL, 2, 2, 1),
(106, 103, '帽子配饰', NULL, 3, 2, 1),
(107,   0, '3C数码', 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=64&h=64&fit=crop', 3, 1, 1),
(108, 107, '手机',   NULL, 1, 2, 1),
(109, 107, '电脑平板', NULL, 2, 2, 1),
(110, 107, '耳机音响', NULL, 3, 2, 1);

INSERT INTO biz_spu
    (id, category_id, title, subtitle, description, main_image, min_price, max_price, status) VALUES
(1001, 101, '纯棉休闲短袖T恤',
 '亲肤透气 · 四季百搭',
 '100% 精梳棉，柔软亲肤，经典圆领版型。适合日常通勤与休闲穿搭，多色多码可选。',
 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=600&h=600&fit=crop',
 79.00, 79.00, 1),

(1002, 101, '商务修身长袖衬衫',
 '免烫面料 · 职场必备',
 '精选抗皱面料，修身剪裁显精神。适合商务会议、面试及正式场合穿着。',
 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600&h=600&fit=crop',
 199.00, 199.00, 1),

(1003, 102, '法式碎花连衣裙',
 '收腰显瘦 · 度假风',
 'V 领碎花印花，高腰 A 字裙摆。春夏出游、约会穿搭首选。',
 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&h=600&fit=crop',
 299.00, 299.00, 1),

(1004, 102, '高腰阔腿牛仔裤',
 '显瘦高腰 · 舒适弹力',
 '高腰设计拉长腿部比例，阔腿版型修饰腿型。含少量氨纶，活动更自如。',
 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=600&h=600&fit=crop',
 259.00, 259.00, 1),

(1005, 105, '经典低帮板鞋',
 '百搭小白鞋 · 橡胶大底',
 '简约低帮设计，耐磨橡胶鞋底，日常街头穿搭经典单品。',
 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=600&h=600&fit=crop',
 399.00, 399.00, 1),

(1006, 104, '专业缓震跑鞋',
 '轻量回弹 · 夜跑反光',
 '中底缓震科技，透气网面鞋身，后跟反光条提升夜跑安全性。',
 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600&h=600&fit=crop',
 599.00, 599.00, 1),

(1007, 106, '可调节棒球帽',
 '纯棉帽身 · 遮阳防晒',
 '弯檐棒球帽，后置可调节扣，男女通用。户外出行、运动遮阳必备。',
 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=600&h=600&fit=crop',
 89.00, 89.00, 1),

(1008, 110, '无线降噪蓝牙耳机',
 '主动降噪 · 30h 续航',
 '混合主动降噪，支持通透模式。蓝牙 5.3，单次续航 8 小时，充电盒合计约 30 小时。',
 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600&h=600&fit=crop',
 299.00, 299.00, 1),

(1009, 108, '智能手机 Pro',
 '旗舰芯片 · 徕卡影像',
 '6.7 英寸 OLED 高刷屏，旗舰处理器，后置三摄系统。支持快充与无线充电。',
 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600&h=600&fit=crop',
 4999.00, 5499.00, 1),

(1010, 109, '轻薄笔记本电脑 14"',
 '2.8K 屏 · 长续航',
 '14 英寸 2.8K 全面屏，金属机身，双风扇散热。适合办公、学习与轻度创作。',
 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&h=600&fit=crop',
 6999.00, 8999.00, 1),

(1011, 109, '11 英寸平板电脑',
 '全面屏 · 支持手写笔',
 '11 英寸 Liquid 视网膜屏，四扬声器，支持官方手写笔与键盘保护套。',
 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600&h=600&fit=crop',
 2499.00, 3299.00, 1),

(1012, 110, '智能运动手表',
 '心率血氧 · 50m 防水',
 '全天候心率/血氧监测，内置 GPS，支持 100+ 运动模式。50 米防水，游泳可戴。',
 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&h=600&fit=crop',
 1999.00, 1999.00, 1);

INSERT INTO biz_sku
    (id, spu_id, sku_code, spec_json, price, stock, image, status) VALUES
(2001, 1001, 'SKU-T1001-WH-M', '{"颜色":"白色","尺码":"M"}',  79.00, 120,
 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400&h=400&fit=crop', 1),
(2002, 1001, 'SKU-T1001-WH-L', '{"颜色":"白色","尺码":"L"}',  79.00,  98,
 'https://images.unsplash.com/photo-1576566588028-4147f3842f27?w=400&h=400&fit=crop', 1),
(2003, 1001, 'SKU-T1001-BK-M', '{"颜色":"黑色","尺码":"M"}',  79.00, 110,
 'https://images.unsplash.com/photo-1583743814966-6a5c4d5e3b8e?w=400&h=400&fit=crop', 1),
(2004, 1001, 'SKU-T1001-BK-L', '{"颜色":"黑色","尺码":"L"}',  79.00,  85,
 'https://images.unsplash.com/photo-1583743814966-6a5c4d5e3b8e?w=400&h=400&fit=crop', 1),
(2005, 1002, 'SKU-T1002-BL-39', '{"颜色":"浅蓝","尺码":"39"}', 199.00,  45,
 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop', 1),
(2006, 1002, 'SKU-T1002-BL-40', '{"颜色":"浅蓝","尺码":"40"}', 199.00,  60,
 'https://images.unsplash.com/photo-1602810318383-e386cc2a3ccf?w=400&h=400&fit=crop', 1),
(2007, 1002, 'SKU-T1002-BL-41', '{"颜色":"浅蓝","尺码":"41"}', 199.00,  38,
 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&h=400&fit=crop', 1),
(2008, 1003, 'SKU-T1003-FL-S', '{"颜色":"碎花","尺码":"S"}', 299.00,  55,
 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=400&h=400&fit=crop', 1),
(2009, 1003, 'SKU-T1003-FL-M', '{"颜色":"碎花","尺码":"M"}', 299.00,  42,
 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=400&h=400&fit=crop', 1),
(2010, 1004, 'SKU-T1004-LB-26', '{"颜色":"浅蓝","尺码":"26"}', 259.00,  70,
 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=400&fit=crop', 1),
(2011, 1004, 'SKU-T1004-LB-27', '{"颜色":"浅蓝","尺码":"27"}', 259.00,  65,
 'https://images.unsplash.com/photo-1541099649105-f69ad21f3246?w=400&h=400&fit=crop', 1),
(2012, 1004, 'SKU-T1004-LB-28', '{"颜色":"浅蓝","尺码":"28"}', 259.00,  58,
 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400&h=400&fit=crop', 1),
(2013, 1005, 'SKU-S1005-WH-42', '{"颜色":"白色","尺码":"42"}', 399.00,  80,
 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop', 1),
(2014, 1005, 'SKU-S1005-WH-43', '{"颜色":"白色","尺码":"43"}', 399.00,  75,
 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400&h=400&fit=crop', 1),
(2015, 1005, 'SKU-S1005-WH-44', '{"颜色":"白色","尺码":"44"}', 399.00,  60,
 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=400&h=400&fit=crop', 1),
(2016, 1005, 'SKU-S1005-BK-42', '{"颜色":"黑色","尺码":"42"}', 399.00,  55,
 'https://images.unsplash.com/photo-1605348537810-1c1721e0d4b0?w=400&h=400&fit=crop', 1),
(2017, 1005, 'SKU-S1005-BK-43', '{"颜色":"黑色","尺码":"43"}', 399.00,  50,
 'https://images.unsplash.com/photo-1605348537810-1c1721e0d4b0?w=400&h=400&fit=crop', 1),
(2018, 1006, 'SKU-S1006-GR-41', '{"颜色":"灰色","尺码":"41"}', 599.00,  40,
 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop', 1),
(2019, 1006, 'SKU-S1006-GR-42', '{"颜色":"灰色","尺码":"42"}', 599.00,  48,
 'https://images.unsplash.com/photo-1605348537810-1c1721e0d4b0?w=400&h=400&fit=crop', 1),
(2020, 1006, 'SKU-S1006-GR-43', '{"颜色":"灰色","尺码":"43"}', 599.00,  35,
 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400&h=400&fit=crop', 1),
(2021, 1007, 'SKU-S1007-NV-OS', '{"颜色":"藏青","尺码":"均码"}',  89.00, 150,
 'https://images.unsplash.com/photo-1588850561407-ed78c282e89b?w=400&h=400&fit=crop', 1),
(2022, 1007, 'SKU-S1007-KH-OS', '{"颜色":"卡其","尺码":"均码"}',  89.00, 130,
 'https://images.unsplash.com/photo-1575428652377-a2d80e2277fc?w=400&h=400&fit=crop', 1),
(2023, 1008, 'SKU-3C1008-BK', '{"颜色":"黑色"}', 299.00, 200,
 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop', 1),
(2024, 1008, 'SKU-3C1008-WH', '{"颜色":"白色"}', 299.00, 180,
 'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=400&h=400&fit=crop', 1),
(2025, 1009, 'SKU-3C1009-BK-128', '{"颜色":"黑色","容量":"128GB"}', 4999.00,  50,
 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400&h=400&fit=crop', 1),
(2026, 1009, 'SKU-3C1009-SL-256', '{"颜色":"银色","容量":"256GB"}', 5499.00,  35,
 'https://images.unsplash.com/photo-1598327275660-828c5c4e1c2e?w=400&h=400&fit=crop', 1),
(2027, 1010, 'SKU-3C1010-SL-16', '{"颜色":"银色","配置":"16G/512G"}', 6999.00,  25,
 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400&h=400&fit=crop', 1),
(2028, 1010, 'SKU-3C1010-GR-32', '{"颜色":"深空灰","配置":"32G/1T"}', 8999.00,  15,
 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400&h=400&fit=crop', 1),
(2029, 1011, 'SKU-3C1011-WF-64',  '{"颜色":"深空灰","容量":"64GB"}',  2499.00,  60,
 'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=400&h=400&fit=crop', 1),
(2030, 1011, 'SKU-3C1011-WF-256', '{"颜色":"深空灰","容量":"256GB"}', 3299.00,  40,
 'https://images.unsplash.com/photo-1561154464-82e9adf32764?w=400&h=400&fit=crop', 1),
(2031, 1012, 'SKU-3C1012-BK', '{"颜色":"黑色"}', 1999.00,  80,
 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop', 1),
(2032, 1012, 'SKU-3C1012-ST', '{"颜色":"星光色"}', 1999.00,  70,
 'https://images.unsplash.com/photo-1434493789847-2f02dc6ca35d?w=400&h=400&fit=crop', 1);
