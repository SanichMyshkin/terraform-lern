terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

// Переменные для токена и идентификатора папки
variable "yc_token" {
  description = "Yandex Cloud API token"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

// Провайдер Yandex Cloud
provider "yandex" {
  token     = var.yc_token
  folder_id = var.yc_folder_id
  zone      = "ru-central1-a"
}

// Создание сети
resource "yandex_vpc_network" "default" {
  name      = "test-network"
  folder_id = var.yc_folder_id
}

// Создание подсети
resource "yandex_vpc_subnet" "default" {
  name           = "test-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.5.0.0/24"]
  folder_id      = var.yc_folder_id
}

// Создание диска
resource "yandex_compute_disk" "default" {
  name      = "test-disk"
  type      = "network-ssd"
  zone      = "ru-central1-a"
  folder_id = var.yc_folder_id

  // Задайте ID образа операционной системы
  image_id = "fd83s8u085j3mq231ago"

  labels = {
    environment = "test"
  }
}

// Создание виртуальной машины
resource "yandex_compute_instance" "default" {
  name        = "test-vm"
  platform_id = "standard-v1"
  zone        = "ru-central1-a"
  folder_id   = var.yc_folder_id

  resources {
    cores  = 2
    memory = 4
  }

  boot_disk {
    // Используем диск, созданный ранее
    disk_id = yandex_compute_disk.default.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true // Подключаем NAT для доступа в интернет
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}" // Подключение SSH-ключа
  }

  labels = {
    environment = "test"
  }
}