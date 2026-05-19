package config

import (
	"os"
	"strconv"
)

const (
	defaultPort     = 8080
	defaultHost     = "0.0.0.0"
	defaultLogLevel = "info"
)

type Config struct {
	Host     string
	Port     int
	LogLevel string
}

func Load() Config {
	port := defaultPort
	if raw := os.Getenv("PORT"); raw != "" {
		if p, err := strconv.Atoi(raw); err == nil && p > 0 {
			port = p
		}
	}

	host := os.Getenv("HOST")
	if host == "" {
		host = defaultHost
	}

	logLevel := os.Getenv("LOG_LEVEL")
	if logLevel == "" {
		logLevel = defaultLogLevel
	}

	return Config{
		Host:     host,
		Port:     port,
		LogLevel: logLevel,
	}
}

func (c Config) Addr() string {
	return c.Host + ":" + strconv.Itoa(c.Port)
}
