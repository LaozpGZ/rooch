// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

use crate::{Client, ClientBuilder};
use anyhow::anyhow;
use rooch_config::config::Config;
use rooch_config::server_config::ServerConfig;
use rooch_types::address::RoochAddress;
use rooch_types::chain_id::RoochChainID;
use serde::Deserialize;
use serde::Serialize;
use serde_with::serde_as;
use std::fmt::{Display, Formatter, Write};
use std::path::PathBuf;

pub const DEFAULT_EXPIRATION_SECS: u64 = 30;
pub const ROOCH_DEV_NET_URL: &str = "https://dev-seed.rooch.network:443/";
pub const ROOCH_TEST_NET_URL: &str = "https://test-seed.rooch.network:443/";

#[serde_as]
#[derive(Serialize, Deserialize, Debug)]
pub struct ClientConfig {
    pub keystore_path: PathBuf,
    pub password_hash: Option<String>,
    pub is_password_empty: bool,
    pub active_address: Option<RoochAddress>,
    pub envs: Vec<Env>,
    pub active_env: Option<String>,
}

impl ClientConfig {
    pub fn new(keystore_path: PathBuf) -> Self {
        ClientConfig {
            keystore_path,
            password_hash: None,
            is_password_empty: true,
            active_address: None,
            envs: vec![],
            active_env: None,
        }
    }

    pub fn get_env(&self, alias: &Option<String>) -> Option<&Env> {
        if let Some(alias) = alias {
            self.envs.iter().find(|env| &env.alias == alias)
        } else {
            self.envs.first()
        }
    }

    pub fn get_active_env(&self) -> Result<&Env, anyhow::Error> {
        self.get_env(&self.active_env).ok_or_else(|| {
            anyhow!(
                "Environment configuration not found for env [{}]",
                self.active_env.as_deref().unwrap_or("None")
            )
        })
    }

    pub fn add_env(&mut self, env: Env) {
        let find_env = self
            .envs
            .iter_mut()
            .find(|other_env| other_env.alias == env.alias);
        if let Some(update_env) = find_env {
            update_env.rpc = env.rpc;
            update_env.ws = env.ws;
        } else {
            self.envs.push(env)
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Env {
    pub alias: String,
    pub rpc: String,
    pub ws: Option<String>,
}

impl Env {
    pub async fn create_rpc_client(
        &self,
        request_timeout: std::time::Duration,
        max_concurrent_requests: Option<u64>,
    ) -> Result<Client, anyhow::Error> {
        let mut builder = ClientBuilder::default();
        builder = builder.request_timeout(request_timeout);
        if let Some(ws_url) = &self.ws {
            builder = builder.ws_url(ws_url);
        }

        if let Some(max_concurrent_requests) = max_concurrent_requests {
            builder = builder.max_concurrent_requests(max_concurrent_requests as usize);
        }

        builder.build(&self.rpc).await
    }

    pub fn new_dev_env() -> Self {
        Self {
            alias: RoochChainID::DEV.chain_name().to_lowercase(),
            rpc: ROOCH_DEV_NET_URL.into(),
            ws: None,
        }
    }

    pub fn new_test_env() -> Self {
        Self {
            alias: RoochChainID::TEST.chain_name().to_lowercase(),
            rpc: ROOCH_TEST_NET_URL.into(),
            ws: None,
        }
    }
}

impl Default for Env {
    fn default() -> Self {
        Env {
            alias: RoochChainID::LOCAL.chain_name().to_lowercase(),
            rpc: ServerConfig::default().url(false),
            ws: None,
        }
    }
}

impl Display for Env {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let mut writer = String::new();
        writeln!(writer, "Active environment : {}", self.alias)?;
        write!(writer, "RPC URL: {}", self.rpc)?;
        if let Some(ws) = &self.ws {
            writeln!(writer)?;
            write!(writer, "Websocket URL: {ws}")?;
        }
        write!(f, "{}", writer)
    }
}

impl Config for ClientConfig {}

impl Display for ClientConfig {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let mut writer = String::new();

        writeln!(writer, "Keystore path : {:?}", self.keystore_path)?;
        write!(writer, "Active address: ")?;
        match self.active_address {
            Some(r) => writeln!(writer, "{}", r)?,
            None => writeln!(writer, "None")?,
        };
        write!(writer, "server: ")?;

        if let Ok(env) = self.get_active_env() {
            write!(writer, "{}", env)?;
        }
        match &self.active_env {
            Some(r) => writeln!(writer, "{}", r)?,
            None => writeln!(writer, "None")?,
        };
        write!(f, "{}", writer)
    }
}
