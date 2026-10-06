-- DormCare: preserve existing values, nullability and defaults.
USE `dormcare`;

ALTER TABLE `users`
  MODIFY COLUMN `role` VARCHAR(20) NOT NULL DEFAULT 'resident';

ALTER TABLE `repair_requests`
  MODIFY COLUMN `category` VARCHAR(30) NOT NULL,
  MODIFY COLUMN `status` VARCHAR(20) NOT NULL DEFAULT 'pending';

ALTER TABLE `request_status_history`
  MODIFY COLUMN `from_status` VARCHAR(20) NULL DEFAULT NULL,
  MODIFY COLUMN `to_status` VARCHAR(20) NOT NULL;
