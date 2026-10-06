-- Keep request/history foreign keys intact when an admin deletes a resident.
ALTER TABLE `dormcare`.`users` ADD COLUMN `deleted_at` DATETIME NULL DEFAULT NULL;
