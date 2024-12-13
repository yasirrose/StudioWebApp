-- MySQL dump 10.13  Distrib 5.7.10, for Win64 (x86_64)
--
-- Host: localhost    Database: ipstudio
-- ------------------------------------------------------
-- Server version	5.7.10-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `action_permissions`
--

DROP TABLE IF EXISTS `action_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `action_permissions` (
  `ap_id` int(11) NOT NULL AUTO_INCREMENT,
  `action_id` int(11) DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `has_access` bit(1) NOT NULL DEFAULT b'1',
  PRIMARY KEY (`ap_id`),
  KEY `action_id` (`action_id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `action_permissions_ibfk_1` FOREIGN KEY (`action_id`) REFERENCES `actions` (`action_id`) ON DELETE CASCADE,
  CONSTRAINT `action_permissions_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `action_permissions`
--

LOCK TABLES `action_permissions` WRITE;
/*!40000 ALTER TABLE `action_permissions` DISABLE KEYS */;
INSERT INTO `action_permissions` VALUES (1,1,1,'2024-11-27 10:10:13','2024-12-12 17:54:17',''),(2,2,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(3,3,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(4,4,1,'2024-11-27 10:10:13','2024-12-12 17:53:49',''),(5,5,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(6,6,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(7,7,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(8,8,1,'2024-11-27 10:10:13','2024-11-28 08:48:42',''),(9,9,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(13,13,1,'2024-11-27 10:10:13','2024-11-29 11:17:19',''),(14,14,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(15,15,1,'2024-11-27 10:10:13','2024-11-27 10:10:13',''),(17,1,2,'2024-11-27 10:12:06','2024-11-29 11:48:22',''),(18,2,2,'2024-11-27 10:12:06','2024-11-29 11:48:22',''),(19,3,2,'2024-11-27 10:12:06','2024-11-29 11:48:23',''),(20,4,2,'2024-11-27 10:12:06','2024-11-29 11:48:23',''),(21,5,2,'2024-11-27 10:12:06','2024-11-29 11:48:24',''),(22,6,2,'2024-11-27 10:12:06','2024-11-29 11:29:59',''),(23,7,2,'2024-11-27 10:12:06','2024-11-29 11:39:23',''),(24,8,2,'2024-11-27 10:12:06','2024-11-29 11:39:24',''),(25,9,2,'2024-11-27 10:12:06','2024-12-12 18:13:31',''),(29,13,2,'2024-11-27 10:12:06','2024-12-12 18:12:25','\0'),(30,14,2,'2024-11-27 10:12:06','2024-12-12 18:12:25','\0'),(31,15,2,'2024-11-27 10:12:06','2024-12-12 18:12:24','\0'),(33,1,3,'2024-11-27 10:12:15','2024-11-28 08:48:45',''),(34,2,3,'2024-11-27 10:12:15','2024-11-27 10:12:15',''),(35,3,3,'2024-11-27 10:12:15','2024-11-27 10:12:15',''),(36,4,3,'2024-11-27 10:12:15','2024-12-12 18:13:01','\0'),(37,5,3,'2024-11-27 10:12:15','2024-12-12 18:13:02','\0'),(38,6,3,'2024-11-27 10:12:15','2024-12-12 18:13:03','\0'),(39,7,3,'2024-11-27 10:12:15','2024-12-12 18:13:04','\0'),(40,8,3,'2024-11-27 10:12:15','2024-12-12 18:13:05','\0'),(41,9,3,'2024-11-27 10:12:15','2024-12-12 18:13:05','\0'),(45,13,3,'2024-11-27 10:12:15','2024-11-29 10:50:11','\0'),(46,14,3,'2024-11-27 10:12:15','2024-12-12 18:13:08','\0'),(47,15,3,'2024-11-27 10:12:15','2024-12-12 18:13:09','\0');
/*!40000 ALTER TABLE `action_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `actions`
--

DROP TABLE IF EXISTS `actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `actions` (
  `action_id` int(11) NOT NULL AUTO_INCREMENT,
  `action_name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `menu_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`action_id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `actions`
--

LOCK TABLES `actions` WRITE;
/*!40000 ALTER TABLE `actions` DISABLE KEYS */;
INSERT INTO `actions` VALUES (1,'Task -> Add Task','2024-11-27 10:08:27','2024-11-29 09:30:21',5),(2,'Task -> Update Task','2024-11-27 10:08:27','2024-11-29 09:30:21',5),(3,'Task -> Delete Task','2024-11-27 10:08:27','2024-11-29 09:30:21',5),(4,'Client -> Add Client','2024-11-27 10:08:27','2024-11-29 09:30:37',3),(5,'Client -> Update Client','2024-11-27 10:08:27','2024-11-29 09:30:37',3),(6,'Client -> Delete Client','2024-11-27 10:08:27','2024-11-29 09:30:37',3),(7,'Project -> Add Project','2024-11-27 10:08:27','2024-11-29 09:31:02',4),(8,'Project -> Update Project','2024-11-27 10:08:27','2024-11-29 09:31:02',4),(9,'Project -> Delete Project','2024-11-27 10:08:27','2024-11-29 09:31:02',4),(13,'User -> Add User','2024-11-27 10:08:27','2024-11-29 09:31:55',2),(14,'User -> Update User','2024-11-27 10:08:27','2024-11-29 09:31:55',2),(15,'User -> Delete User','2024-11-27 10:08:27','2024-11-29 09:31:55',2);
/*!40000 ALTER TABLE `actions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `clients` (
  `client_id` int(11) NOT NULL AUTO_INCREMENT,
  `client_main_id` int(11) DEFAULT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `client_pin` varchar(10) DEFAULT NULL,
  `client_default_page` varchar(100) DEFAULT NULL,
  `client_active` tinyint(1) DEFAULT '1',
  `client_deleted` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`client_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES (1,4,'Jane','Doe','janedoe@example.com','+1234567890','123456','scheduledtasks',0,NULL,'2024-10-25 20:36:23','2024-12-13 15:05:15'),(4,1,'John','Doe TRT','trtjohndoe2@example.com','+1234567890','867868','scheduledtasks',1,'2024-11-07 15:57:24','2024-10-25 20:39:32','2024-11-18 11:26:53'),(5,1,'John Test','DoeJohnLatest','johndoe26@example.com','+1234567890','915820','scheduledtasks',1,NULL,'2024-10-25 20:40:35','2024-12-13 15:05:27'),(6,4,'Jane','Doe','janesssadasdsdsadasdadoe@example.com','+1234567890','915820','scheduledtasks',0,'2024-12-02 13:21:52','2024-10-25 21:06:35','2024-12-02 08:40:44'),(9,4,'John_9999','Doe_9999','johndoe9@example.com','+1234567899','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:44'),(10,4,'John_10','Doe_10','johndoe10@example.com','+12345678910','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:44'),(11,2,'John_11','Doe_11','johndoe11@example.com','+12345678911','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(12,2,'John_12','Doe_12','johndoe12@example.com','+12345678912','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(13,3,'John_13','Doe_13','johndoe13@example.com','+12345678913','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-11-18 11:26:53'),(14,3,'John_14','Doe_14','johndoe14@example.com','+12345678914','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-11-18 11:26:53'),(15,3,'John_15','Doe_15','johndoe15@example.com','+12345678915','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-11-18 11:26:53'),(16,2,'John_16','Doe_16','johndoe16@example.com','+12345678916','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(17,2,'John_17','Doe_17','johndoe17@example.com','+12345678917','915820','scheduledtasks',0,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(18,4,'John_18','Doe_19999','johndoe18@example.com',NULL,'915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-11-18 11:26:53'),(19,4,'John_19','Doe_19','johndoe19@example.com','+12345678919','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-11-18 11:26:53'),(20,4,'John_20','Doe_20','johndoe20@example.com','+12345678920','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-11-18 11:26:53'),(21,2,'John_21','Doe_21','johndoe21@example.com','+12345678921','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(22,2,'John_22','Doe_22','johndoe22@example.com','+12345678922','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(23,2,'John_23','Doe_23','johndoe23@example.com','+12345678923','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(24,2,'John_24','Doe_24','johndoe24@example.com','+12345678924','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(25,2,'John_25','Doe_25','johndoe25@example.com','+12345678925','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40'),(26,2,'John_26','Doe_26','johndoe2888@example.com','+12345678926','915820','scheduledtasks',1,NULL,'2024-10-25 20:36:23','2024-12-02 08:40:40');
/*!40000 ALTER TABLE `clients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menu_permissions`
--

DROP TABLE IF EXISTS `menu_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menu_permissions` (
  `mp_id` int(11) NOT NULL AUTO_INCREMENT,
  `menu_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  `has_access` tinyint(1) DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`mp_id`),
  KEY `module_id` (`menu_id`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `menu_permissions_ibfk_1` FOREIGN KEY (`menu_id`) REFERENCES `menus` (`menu_id`) ON DELETE CASCADE,
  CONSTRAINT `menu_permissions_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menu_permissions`
--

LOCK TABLES `menu_permissions` WRITE;
/*!40000 ALTER TABLE `menu_permissions` DISABLE KEYS */;
INSERT INTO `menu_permissions` VALUES (1,1,1,1,'2024-11-27 08:29:58','2024-11-28 08:35:50'),(2,2,1,1,'2024-11-27 08:29:58','2024-11-28 09:30:35'),(3,3,1,1,'2024-11-27 08:29:58','2024-12-12 17:53:35'),(4,4,1,1,'2024-11-27 08:29:58','2024-11-28 08:48:54'),(5,5,1,1,'2024-11-27 08:29:58','2024-11-28 08:48:53'),(6,6,1,1,'2024-11-27 08:29:58','2024-11-28 08:48:52'),(7,7,1,1,'2024-11-27 08:29:58','2024-11-28 08:48:52'),(8,1,2,1,'2024-11-27 08:29:58','2024-12-02 08:42:13'),(9,2,2,0,'2024-11-27 08:29:58','2024-12-02 13:15:58'),(10,3,2,1,'2024-11-27 08:29:58','2024-11-29 08:05:22'),(11,4,2,1,'2024-11-27 08:29:58','2024-11-29 08:05:26'),(12,5,2,1,'2024-11-27 08:29:58','2024-11-28 15:00:45'),(13,6,2,1,'2024-11-27 08:29:58','2024-11-27 08:29:58'),(14,7,2,0,'2024-11-27 08:29:58','2024-12-12 18:11:48'),(15,1,3,1,'2024-11-27 08:29:58','2024-11-27 08:29:58'),(16,2,3,0,'2024-11-27 08:29:58','2024-12-12 18:10:49'),(17,3,3,0,'2024-11-27 08:29:58','2024-12-12 18:10:51'),(18,4,3,0,'2024-11-27 08:29:58','2024-12-12 18:10:52'),(19,5,3,1,'2024-11-27 08:29:58','2024-11-27 08:29:58'),(20,6,3,1,'2024-11-27 08:29:58','2024-11-27 08:29:58'),(21,7,3,0,'2024-11-27 08:29:58','2024-12-12 18:10:54');
/*!40000 ALTER TABLE `menu_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `menus`
--

DROP TABLE IF EXISTS `menus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `menus` (
  `menu_id` int(11) NOT NULL AUTO_INCREMENT,
  `menu_name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`menu_id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `menus`
--

LOCK TABLES `menus` WRITE;
/*!40000 ALTER TABLE `menus` DISABLE KEYS */;
INSERT INTO `menus` VALUES (1,'Dashboard','2024-11-27 08:17:16','2024-11-27 08:17:16'),(2,'Users','2024-11-27 08:17:16','2024-11-27 08:28:02'),(3,'Clients','2024-11-27 08:17:16','2024-11-27 08:17:16'),(4,'Client Projects','2024-11-27 08:17:16','2024-11-27 08:17:16'),(5,'Project Tasks','2024-11-27 08:17:16','2024-11-27 08:17:16'),(6,'Scheduled Tasks','2024-11-27 08:17:16','2024-11-27 08:17:16'),(7,'Permissions','2024-11-27 08:17:16','2024-11-27 08:17:16');
/*!40000 ALTER TABLE `menus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `projects`
--

DROP TABLE IF EXISTS `projects`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `projects` (
  `project_id` int(11) NOT NULL AUTO_INCREMENT,
  `project_name` varchar(255) DEFAULT NULL,
  `asana_api_client_id` varchar(255) DEFAULT NULL,
  `asana_api_client_secret` varchar(255) DEFAULT NULL,
  `asana_project_name` varchar(255) DEFAULT NULL,
  `project_active` tinyint(1) DEFAULT '1',
  `project_deleted` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT NULL,
  `client_id` int(11) DEFAULT NULL,
  `project_gid` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`project_id`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `projects`
--

LOCK TABLES `projects` WRITE;
/*!40000 ALTER TABLE `projects` DISABLE KEYS */;
INSERT INTO `projects` VALUES (1,'Project Alpha test','client_id_001','secret_001','Alpha Project Asana',1,NULL,'2024-11-01 10:21:53','2024-11-01 13:41:53',9,NULL),(2,'Project Beta','client_id_002','secret_002','Beta Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,15,NULL),(3,'Project Gamma','client_id_003','secret_003','Gamma Project Asana',1,NULL,'2024-11-01 10:21:53','2024-11-01 20:47:08',15,NULL),(4,'Project Delta TT','client_id_004','secret_004','Delta Project Asana',1,NULL,'2024-11-01 10:21:53','2024-11-01 13:18:22',9,NULL),(5,'Project test 2 WWW','client_id_0054343434','secret_005','Epsilon Project Asanadfsdfsdfsdfsdf',1,NULL,'2024-11-01 10:21:53',NULL,9,NULL),(6,'Project Zeta BETA','client_id_006','secret_006','Zeta Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,9,NULL),(7,'Project Etatt','client_id_007','secret_007','Eta Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,12,NULL),(8,'Project Theta YYi0','client_id_008','secret_008','Theta Project Asana',0,NULL,'2024-11-01 10:21:53','2024-11-07 08:12:55',12,NULL),(9,'Project Iota 00','client_id_009','secret_009','Iota Project Asana',1,NULL,'2024-11-01 10:21:53','2024-11-07 08:14:15',9,NULL),(10,'Project Kappa QQ','client_id_010','secret_010','Kappa Project Asana',1,NULL,'2024-11-01 10:21:53','2024-11-08 14:06:31',1,NULL),(11,'Project Lambda TRT','client_id_011','secret_011','Lambda Project Asana',1,NULL,'2024-11-01 10:21:53','2024-11-06 07:59:11',1,NULL),(12,'Project Mu --TTTTTT','client_id_012','secret_012','Mu Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,12,NULL),(13,'Project Nu','client_id_013','secret_013','Nu Project Asana',0,NULL,'2024-11-01 10:21:53','2024-11-07 08:14:12',12,NULL),(14,'Project Xi','client_id_014','secret_014','Xi Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,12,NULL),(15,'Project Omicron','client_id_015','secret_015','Omicron Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,6,NULL),(16,'Project Pi','client_id_016','secret_016','Pi Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,6,NULL),(17,'Project Rho','client_id_017','secret_017','Rho Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,18,NULL),(18,'Project Sigma','client_id_018','secret_018','Sigma Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,18,NULL),(19,'Project Tau','client_id_019','secret_019','Tau Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,18,NULL),(20,'Project Upsilon','client_id_020','secret_020','Upsilon Project Asana',1,NULL,'2024-11-01 10:21:53',NULL,18,NULL);
/*!40000 ALTER TABLE `projects` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `role_id` int(11) NOT NULL AUTO_INCREMENT,
  `role_name` varchar(50) NOT NULL,
  `description` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Super Admin','Has full access to all resources and settings','2024-10-18 14:26:34','2024-10-29 13:26:42'),(2,'Admin','Can edit content but cannot manage users or settings','2024-10-18 14:26:34','2024-10-29 09:00:35'),(3,'Client User','Can only view content and reports, no editing rights','2024-10-18 14:26:34','2024-10-24 09:12:00');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `task_statuses`
--

DROP TABLE IF EXISTS `task_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `task_statuses` (
  `status_id` int(11) NOT NULL AUTO_INCREMENT,
  `status_name` varchar(50) NOT NULL,
  `status_description` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`status_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `task_statuses`
--

LOCK TABLES `task_statuses` WRITE;
/*!40000 ALTER TABLE `task_statuses` DISABLE KEYS */;
INSERT INTO `task_statuses` VALUES (1,'Pending','Task is awaiting action','2024-11-06 10:15:28','2024-11-06 10:15:28'),(2,'In Progress','Task is currently being worked on','2024-11-06 10:15:28','2024-11-06 10:15:28'),(3,'Completed','Task has been completed successfully','2024-11-06 10:15:28','2024-11-06 10:15:28'),(4,'Testing','Task is under testing phase','2024-11-06 10:15:28','2024-11-06 10:15:28'),(5,'On Hold','Task is temporarily on hold','2024-11-06 10:15:28','2024-11-06 10:15:28');
/*!40000 ALTER TABLE `task_statuses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tasks`
--

DROP TABLE IF EXISTS `tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tasks` (
  `task_id` int(11) NOT NULL AUTO_INCREMENT,
  `project_id` int(11) DEFAULT NULL,
  `task_name` varchar(255) NOT NULL,
  `description` text,
  `assigned_to` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `status_id` int(11) DEFAULT '1',
  `task_start_date` date DEFAULT NULL,
  `task_end_date` date DEFAULT NULL,
  `task_start_time` time DEFAULT NULL,
  `task_end_time` time DEFAULT NULL,
  `is_all_day` bit(1) DEFAULT NULL,
  `project_gid` bigint(20) unsigned DEFAULT NULL,
  `task_gid` bigint(20) unsigned DEFAULT NULL,
  PRIMARY KEY (`task_id`),
  UNIQUE KEY `tasks_unique` (`task_gid`)
) ENGINE=InnoDB AUTO_INCREMENT=114 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tasks`
--

LOCK TABLES `tasks` WRITE;
/*!40000 ALTER TABLE `tasks` DISABLE KEYS */;
INSERT INTO `tasks` VALUES (1,101,'Task Alpha','Description for Task Alpha',1,'2024-10-30 08:30:00','2024-10-30 08:30:00',1,'2024-11-01','2024-11-01','08:00:00','10:30:00','\0',NULL,NULL),(2,101,'Task Beta','Description for Task Beta',2,'2024-10-30 09:15:00','2024-10-30 09:15:00',2,'2024-11-02','2024-11-02','09:00:00','12:00:00','\0',NULL,NULL),(3,102,'Task Gamma','Description for Task Gamma',3,'2024-10-30 10:00:00','2024-10-30 10:00:00',1,'2024-11-03','2024-11-03','10:00:00','13:00:00','\0',NULL,NULL),(4,102,'Task Delta','Description for Task Delta',4,'2024-10-30 10:30:00','2024-10-30 10:30:00',3,'2024-11-04','2024-11-04','08:30:00','11:30:00','\0',NULL,NULL),(5,103,'Task Epsilon','Description for Task Epsilon',5,'2024-10-30 11:00:00','2024-10-30 11:00:00',2,'2024-11-05','2024-11-05','14:00:00','17:00:00','\0',NULL,NULL),(6,103,'Task Zeta','Description for Task Zeta',6,'2024-10-30 11:30:00','2024-10-30 11:30:00',1,'2024-11-06','2024-11-06','09:30:00','12:30:00','\0',NULL,NULL),(7,104,'Task Eta','Description for Task Eta',7,'2024-10-30 12:00:00','2024-10-30 12:00:00',3,'2024-11-07','2024-11-07','15:00:00','18:00:00','\0',NULL,NULL),(8,104,'Task Theta','Description for Task Theta',8,'2024-10-30 12:30:00','2024-10-30 12:30:00',2,'2024-11-08','2024-11-08','08:00:00','10:30:00','\0',NULL,NULL),(9,105,'Task Iota','Description for Task Iota',9,'2024-10-30 13:00:00','2024-10-30 13:00:00',1,'2024-11-09','2024-11-09','11:00:00','14:00:00','\0',NULL,NULL),(10,105,'Task Kappa','Description for Task Kappa',10,'2024-10-30 13:30:00','2024-11-13 19:59:57',3,'2024-11-10','2024-11-10','09:00:00','16:00:00','\0',NULL,NULL),(71,1,'Task 1','Description for task 1',5,'2024-11-12 15:47:04','2024-11-13 12:33:41',2,'2024-11-12','2024-11-12','09:00:00','12:00:00','\0',NULL,NULL),(72,2,'Task 2','Description for task 2',3,'2024-11-12 15:47:04','2024-11-12 15:47:04',1,'2024-11-17','2024-11-19','09:00:00','11:00:00','',NULL,NULL),(76,6,'Task 6','Description for task 6',12,'2024-11-12 15:47:04','2024-11-12 15:47:04',1,'2024-11-21','2024-11-23','13:00:00','15:00:00','',NULL,NULL),(77,7,'Task 7','Description for task 7',6,'2024-11-12 15:47:04','2024-11-12 15:47:04',2,'2024-11-22','2024-11-24','14:00:00','16:00:00','\0',NULL,NULL),(78,8,'Task 8','Description for task 8',8,'2024-11-12 15:47:04','2024-11-12 15:47:04',3,'2024-11-23','2024-11-25','15:00:00','17:00:00','',NULL,NULL),(79,9,'Task 9','Description for task 9',1,'2024-11-12 15:47:04','2024-11-12 15:47:04',4,'2024-11-24','2024-11-26','16:00:00','18:00:00','\0',NULL,NULL),(80,10,'Task 10','Description for task 10',4,'2024-11-12 15:47:04','2024-11-13 20:11:18',1,'2024-11-15','2024-11-15','10:00:00','19:00:00','\0',NULL,NULL),(81,11,'Task 11','Description for task 11',9,'2024-11-12 15:47:04','2024-11-12 15:47:04',1,'2024-11-26','2024-11-28','18:00:00','20:00:00','\0',NULL,NULL),(82,12,'Task 12','Description for task 12',11,'2024-11-12 15:47:04','2024-11-12 15:47:04',2,'2024-11-27','2024-11-29','19:00:00','21:00:00','',NULL,NULL),(83,13,'Task 13','Description for task 13',3,'2024-11-12 15:47:04','2024-11-13 16:30:46',3,'2024-11-11','2024-11-12','20:00:00','22:00:00','',NULL,NULL),(84,14,'Task 14','Description for task 14',2,'2024-11-12 15:47:04','2024-11-13 16:31:47',4,'2024-11-15','2024-11-16','21:00:00','23:00:00','',NULL,NULL),(85,15,'Task 15','Description for task 15',10,'2024-11-12 15:47:04','2024-11-12 15:47:04',5,'2024-11-30','2024-12-02','22:00:00','00:00:00','\0',NULL,NULL),(86,16,'Task 16','Description for task 16',7,'2024-11-12 15:47:04','2024-11-12 15:47:04',1,'2024-12-01','2024-12-03','23:00:00','01:00:00','',NULL,NULL),(87,17,'Task 17','Description for task 17',12,'2024-11-12 15:47:04','2024-11-12 15:47:04',2,'2024-12-02','2024-12-04','00:00:00','02:00:00','\0',NULL,NULL),(88,18,'Task 18','Description for task 18',5,'2024-11-12 15:47:04','2024-11-12 15:47:04',3,'2024-12-03','2024-12-05','01:00:00','03:00:00','',NULL,NULL),(89,19,'Task 19','Description for task 19',6,'2024-11-12 15:47:04','2024-11-12 15:47:04',4,'2024-12-04','2024-12-06','02:00:00','04:00:00','\0',NULL,NULL),(90,20,'Task 20','Description for task 20',4,'2024-11-12 15:47:04','2024-11-12 15:47:04',5,'2024-12-05','2024-12-07','03:00:00','05:00:00','',NULL,NULL),(91,201,'Task Alpha','Description for Task Alpha',1,'2024-11-30 08:00:00','2024-11-30 08:00:00',1,'2024-12-01','2024-12-01','08:00:00','10:30:00','\0',NULL,NULL),(92,201,'Task Beta','Description for Task Beta',2,'2024-11-30 09:00:00','2024-11-30 09:00:00',2,'2024-12-02','2024-12-02','09:00:00','11:30:00','\0',NULL,NULL),(93,202,'Task Gamma','Description for Task Gamma',3,'2024-11-30 10:00:00','2024-11-30 10:00:00',1,'2024-12-03','2024-12-03','10:00:00','12:30:00','\0',NULL,NULL),(94,202,'Task Delta','Description for Task Delta',4,'2024-11-30 10:30:00','2024-11-30 10:30:00',3,'2024-12-04','2024-12-04','08:30:00','11:00:00','\0',NULL,NULL),(95,203,'Task Epsilon','Description for Task Epsilon',5,'2024-11-30 11:00:00','2024-11-30 11:00:00',2,'2024-12-05','2024-12-05','14:00:00','16:30:00','\0',NULL,NULL),(96,203,'Task Zeta','Description for Task Zeta',6,'2024-11-30 11:30:00','2024-11-30 11:30:00',1,'2024-12-06','2024-12-06','09:30:00','12:00:00','\0',NULL,NULL),(97,204,'Task Eta','Description for Task Eta',7,'2024-11-30 12:00:00','2024-11-30 12:00:00',3,'2024-12-07','2024-12-07','15:00:00','18:00:00','\0',NULL,NULL),(98,204,'Task Theta','Description for Task Theta',8,'2024-11-30 12:30:00','2024-11-30 12:30:00',2,'2024-12-08','2024-12-08','08:00:00','10:30:00','\0',NULL,NULL),(99,205,'Task Iota','Description for Task Iota',9,'2024-11-30 13:00:00','2024-11-30 13:00:00',1,'2024-12-09','2024-12-09','11:00:00','13:30:00','\0',NULL,NULL),(100,1205,'Task Kappa','Description for Task Kappa',10,'2024-11-30 13:30:00','2024-11-30 13:30:00',3,'2024-12-10','2024-12-10','13:00:00','16:00:00','\0',NULL,NULL),(103,1207,'Task Nu','Description for Task Nu',13,'2024-11-30 15:00:00','2024-11-30 15:00:00',3,'2024-12-13','2024-12-13','08:30:00','11:00:00','\0',NULL,NULL),(104,1207,'Task Xi','Description for Task Xi',14,'2024-11-30 15:30:00','2024-11-30 15:30:00',2,'2024-12-14','2024-12-14','13:00:00','15:30:00','\0',NULL,NULL),(105,1208,'Task Omicron','Description for Task Omicron',15,'2024-11-30 16:00:00','2024-11-30 16:00:00',1,'2024-12-15','2024-12-15','10:00:00','12:30:00','\0',NULL,NULL),(106,1208,'Task Pi','Description for Task Pi',16,'2024-11-30 16:30:00','2024-11-30 16:30:00',3,'2024-12-16','2024-12-16','14:00:00','17:00:00','\0',NULL,NULL),(107,1209,'Task Rho','Description for Task Rho',17,'2024-11-30 17:00:00','2024-11-30 17:00:00',2,'2024-12-17','2024-12-17','09:00:00','11:30:00','\0',NULL,NULL),(109,1210,'Task Tau   VVVV','Description for Task Tau',19,'2024-11-30 18:00:00','2024-12-13 16:23:44',3,'2024-12-19','2024-12-19',NULL,NULL,'\0',NULL,NULL),(110,2210,'Task Upsilon','Description for Task Upsilon',20,'2024-11-30 18:30:00','2024-11-30 18:30:00',2,'2024-12-20','2024-12-20','15:00:00','17:30:00','\0',NULL,NULL);
/*!40000 ALTER TABLE `tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `role_id` int(11) NOT NULL DEFAULT '1',
  `first_name` varchar(100) DEFAULT NULL,
  `last_name` varchar(100) DEFAULT NULL,
  `company` varchar(255) DEFAULT NULL,
  `company_site` varchar(255) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `user_active` tinyint(1) DEFAULT '1',
  `user_deleted` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `avatar` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `role_id` (`role_id`),
  CONSTRAINT `users_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,1,'JOHN ','DOE','TEST COMPNY','testcompany.com','UK','+1234567891','456 Elm St','john.doe@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:00:00','2024-12-12 16:07:31',''),(2,2,'Jane','Smith TRTR','Company B','www.companyb.com','UK','+1234567891','456 Elm St','jane.smith@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',0,NULL,'2024-10-29 04:05:00','2024-12-12 16:07:31','avatar2.png'),(3,3,'Jim','Brown','Company C','www.companyc.com','Canada','+1234567892','789 Maple St','jim.brown@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:10:00','2024-12-12 16:07:31','avatar3.png'),(4,1,'Jessica','Davis','Company D','www.companyd.com','Australia','+1234567893','101 Pine Stsdasdasda','jessica.davis@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:15:00','2024-12-12 16:07:31',''),(5,2,'Michael','Clark','Company E','www.companye.com','Germany','+1234567894','202 Cedar St','michael.clark@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:20:00','2024-12-12 15:51:04',''),(6,3,'Emily','Harris tt','Company F','www.companyf.com','France','+1234567895','303 Birch St','emily.harris@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:25:00','2024-12-12 15:51:04',''),(7,1,'Daniel','Martinez','Company G','www.companyg.com','Mexico','+1234567896','404 Oak St','daniel.martinez@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',0,NULL,'2024-10-29 04:30:00','2024-12-12 16:07:31','avatar7.png'),(8,2,'Olivia','Garcia','Company H','www.companyh.com','Spain','+1234567897','505 Cherry St','olivia.garcia@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:35:00','2024-12-12 15:51:04',''),(9,3,'David','Wilson','Company I','www.companyi.com','Italy','+1234567898','606 Walnut St','david.wilson@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:40:00','2024-12-12 16:07:31','avatar9.png'),(10,1,'Sophia','Anderson','Company J','www.companyj.com','Brazil','+1234567899','707 Spruce St','sophia.anderson@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:45:00','2024-12-12 16:07:31','avatar10.png'),(11,2,'Matthew','Taylor tetsetet','Company K','www.companyk.com','Japan','+1234567810','808 Redwood St','matthew.taylor@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',0,NULL,'2024-10-29 04:50:00','2024-12-12 16:07:31',''),(12,3,'Isabella','Thomas','Company L','www.companyl.com','India','+1234567811','909 Cypress St','isabella.thomas@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 04:55:00','2024-12-12 16:07:31','avatar12.png'),(13,1,'Joshua','Moore TEST','Company M','www.companym.com','China','+1234567812','1010 Fir St','joshua.moore@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',0,NULL,'2024-10-29 05:00:00','2024-12-12 16:07:31',''),(14,2,'Mia','Jackson','Company N','www.companyn.com','Russia','+1234567813','1111 Ash St','mia.jackson@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 05:05:00','2024-12-12 16:07:31','avatar14.png'),(15,3,'Ethan','White','Company O','www.companyo.com','South Africa','+1234567814','1212 Hemlock St','ethan.white@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 05:10:00','2024-12-12 15:51:04','avatar15.png'),(16,1,'Ava','Harris','Company P','www.companyp.com','Netherlands','+1234567815','1313 Cedar St','ava.harris@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 05:15:00','2024-12-12 16:07:31',''),(17,2,'James','King','Company Q','www.companyq.com','Sweden','+1234567816','1414 Dogwood St','james.king@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 05:20:00','2024-12-12 16:07:31','avatar17.png'),(18,3,'Chloe','Wright','Company R','www.companyr.com','New Zealand','+1234567817','1515 Alder St','chloe.wright@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 05:25:00','2024-12-12 15:51:04','avatar18.png'),(19,1,'Alexander','Lopez  TTT','Company S','www.companys.com','Norway','+1234567818','1616 Elm St','alexander.lopez@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 05:30:00','2024-12-12 16:07:31',''),(20,2,'Amelia','Scott','Company T','www.companyt.com','Switzerland','+1234567819','1717 Sycamore St','amelia.scott@example.com','FF7BD97B1A7789DDD2775122FD6817F3173672DA9F802CEEC57F284325BF589F',1,NULL,'2024-10-29 05:35:00','2024-12-12 16:07:31','avatar20.png');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'ipstudio'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-12-13 20:06:22
