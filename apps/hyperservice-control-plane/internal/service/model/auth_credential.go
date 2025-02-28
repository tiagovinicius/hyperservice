package model

type AuthCredentials struct {
	User     string `json:"user,omitempty"`
	Password string `json:"password,omitempty"`
}
