use std::fs;
use std::path::PathBuf;

fn main() {
    // Ensure a bundle exists for include_bytes! in wasm builds.
    // Priority:
    // 1) use CHIPCADE_BUNDLE if set
    // 2) use test/build/program.bin if it exists
    // 3) fallback: create a placeholder image with header at 0xF000
    let bundle_env = std::env::var("CHIPCADE_BUNDLE").ok();
    let src_candidates: Vec<PathBuf> = bundle_env
        .into_iter()
        .map(PathBuf::from)
        .chain(std::iter::once(PathBuf::from("test/build/program.bin")).filter(|p| p.exists()))
        .collect();

    let build_dir = PathBuf::from("build");
    let dest_bundle = build_dir.join("program.bin");
    let _ = fs::create_dir_all(&build_dir);

    if let Some(src) = src_candidates.into_iter().find(|p| p.exists()) {
        if let Err(e) = fs::copy(&src, &dest_bundle) {
            eprintln!(
                "build.rs: failed to copy bundle from {} to {}: {e}",
                src.display(),
                dest_bundle.display()
            );
        }
        return;
    }

    // Placeholder: flat 64K image with empty header at 0xF000.
    let mut image = vec![0u8; 0x10000];
    let meta_addr = 0xF000;
    if meta_addr + 8 <= image.len() {
        image[meta_addr..meta_addr + 4].copy_from_slice(b"CHPB");
        image[meta_addr + 4..meta_addr + 8].copy_from_slice(&(0u32).to_le_bytes());
    }
    if let Err(e) = fs::write(&dest_bundle, &image) {
        eprintln!(
            "build.rs: failed to write placeholder bundle to {}: {e}",
            dest_bundle.display()
        );
    }
}
