use solana_sdk::signature::{Keypair, Signer};
use std::sync::atomic::{AtomicUsize, AtomicBool, Ordering};
use std::sync::Arc;
use std::env;
use std::thread;
use std::time::Duration;
use std::io::{self, Write};
use serde_json::json;

fn main() {
    let args: Vec<String> = env::args().collect();
    
    // CLI 兼容模式：
    // 1) 单条件: <pattern> <count> <prefix|suffix>
    // 2) 双条件: <prefix_pattern> <suffix_pattern> both [count]
    let mut position = args.get(3).unwrap_or(&"suffix".to_string()).to_lowercase();
    let mut count: usize = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(5);

    // 默认单条件参数
    let mut prefix_pattern = args.get(1).unwrap_or(&"test".to_string()).to_string();
    let mut suffix_pattern = String::new();

    // 若使用双条件：args[3] == "both"
    if position == "both" {
        // 解析前后缀模式
        prefix_pattern = args.get(1).unwrap_or(&"".to_string()).to_string();
        suffix_pattern = args.get(2).unwrap_or(&"".to_string()).to_string();
        // 可选count位于args[4]
        count = args.get(4).and_then(|s| s.parse().ok()).unwrap_or(1);
    }
    
    let total_attempts = Arc::new(AtomicUsize::new(0));
    
    for target_num in 1..=count {
        let pattern_clone = prefix_pattern.clone();
        let suffix_clone = suffix_pattern.clone();
        let position_clone = position.clone();
        let attempts = Arc::clone(&total_attempts);
        let found = Arc::new(AtomicBool::new(false));
        
        // Spawn progress thread
        let progress_attempts = Arc::clone(&attempts);
        let progress_found = Arc::clone(&found);
        let progress_handle = thread::spawn(move || {
            let mut last_reported = 0;
            while !progress_found.load(Ordering::SeqCst) {
                let current = progress_attempts.load(Ordering::SeqCst);
                // Report every 10000 attempts or every second if we have new attempts
                if current > last_reported && (current >= last_reported + 10000 || current == 10000) {
                    println!("{}", json!({
                        "type": "progress",
                        "attempts": current,
                        "found": target_num - 1,
                        "searching_for": target_num
                    }));
                    io::stdout().flush().unwrap();
                    last_reported = current;
                }
                thread::sleep(Duration::from_millis(500));
            }
        });
        
        // Search for address
        loop {
            attempts.fetch_add(1, Ordering::SeqCst);
            
            let keypair = Keypair::new();
            let address = keypair.pubkey().to_string();
            
            // 大小写严格匹配：
            let matches = if position_clone == "prefix" {
                address.starts_with(&pattern_clone)
            } else if position_clone == "suffix" {
                address.ends_with(&pattern_clone)
            } else { // both
                (!pattern_clone.is_empty() && address.starts_with(&pattern_clone)) &&
                (!suffix_clone.is_empty() && address.ends_with(&suffix_clone))
            };
            
            if matches {
                found.store(true, Ordering::SeqCst);
                let private_key = bs58::encode(&keypair.to_bytes()).into_string();
                
                println!("{}", json!({
                    "type": "found",
                    "address": address,
                    "private_key": private_key,
                    "attempts": attempts.load(Ordering::SeqCst),
                    "index": target_num,
                    "position": position_clone
                }));
                io::stdout().flush().unwrap();
                
                progress_handle.join().ok();
                break;
            }
        }
    }
    
    println!("{}", json!({
        "type": "complete",
        "total_attempts": total_attempts.load(Ordering::SeqCst),
        "total_found": count
    }));
    io::stdout().flush().unwrap();
}