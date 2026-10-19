/*
Navicat MySQL Data Transfer

Source Server         : 192.168.79.130_3307
Source Server Version : 50725
Source Host           : 192.168.79.130:3307
Source Database       : cloud_order

Target Server Type    : MYSQL
Target Server Version : 50725
File Encoding         : 65001

Date: 2026-10-20 02:08:58
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `tb_order`
-- ----------------------------
DROP TABLE IF EXISTS `tb_order`;
CREATE TABLE `tb_order` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '订单id',
  `user_id` bigint(20) NOT NULL COMMENT '用户id',
  `name` varchar(100) DEFAULT NULL COMMENT '商品名称',
  `price` bigint(20) NOT NULL COMMENT '商品价格',
  `num` int(10) DEFAULT '0' COMMENT '商品数量',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `username` (`name`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=109 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of tb_order
-- ----------------------------
INSERT INTO `tb_order` VALUES ('101', '1', 'Apple 苹果 iPhone 12 ', '699900', '1');
INSERT INTO `tb_order` VALUES ('102', '2', '雅迪 yadea 新国标电动车', '209900', '1');
INSERT INTO `tb_order` VALUES ('103', '3', '骆驼（CAMEL）休闲运动鞋女', '43900', '1');
INSERT INTO `tb_order` VALUES ('104', '4', '小米10 双模5G 骁龙865', '359900', '1');
INSERT INTO `tb_order` VALUES ('105', '5', 'OPPO Reno3 Pro 双模5G 视频双防抖', '299900', '1');
INSERT INTO `tb_order` VALUES ('106', '6', '美的（Midea) 新能效 冷静星II ', '544900', '1');
INSERT INTO `tb_order` VALUES ('107', '2', '西昊/SIHOO 人体工学电脑椅子', '79900', '1');
INSERT INTO `tb_order` VALUES ('108', '3', '梵班（FAMDBANN）休闲男鞋', '31900', '1');
