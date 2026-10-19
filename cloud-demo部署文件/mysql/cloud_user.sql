/*
Navicat MySQL Data Transfer

Source Server         : 192.168.79.130_3307
Source Server Version : 50725
Source Host           : 192.168.79.130:3307
Source Database       : cloud_user

Target Server Type    : MYSQL
Target Server Version : 50725
File Encoding         : 65001

Date: 2026-10-20 02:09:06
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `tb_user`
-- ----------------------------
DROP TABLE IF EXISTS `tb_user`;
CREATE TABLE `tb_user` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(100) DEFAULT NULL COMMENT '收件人',
  `address` varchar(255) DEFAULT NULL COMMENT '地址',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `username` (`username`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of tb_user
-- ----------------------------
INSERT INTO `tb_user` VALUES ('1', '柳岩', '湖南省衡阳市');
INSERT INTO `tb_user` VALUES ('2', '文二狗', '陕西省西安市');
INSERT INTO `tb_user` VALUES ('3', '华沉鱼', '湖北省十堰市');
INSERT INTO `tb_user` VALUES ('4', '张必沉', '天津市');
INSERT INTO `tb_user` VALUES ('5', '郑爽爽', '辽宁省沈阳市大东区');
INSERT INTO `tb_user` VALUES ('6', '范兵兵', '山东省青岛市');
