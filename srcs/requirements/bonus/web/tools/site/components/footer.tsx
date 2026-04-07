"use client"

import { motion, AnimatePresence } from "framer-motion"
import { useState } from "react"
import { siteContent } from "@/lib/site-content"

export function Footer() {
  const [showSpotifyEmbed, setShowSpotifyEmbed] = useState(false)

  return (
    <motion.footer
      className="px-4 sm:px-6 md:px-8 pt-3 sm:pt-4 md:pt-6 pb-4 sm:pb-6 md:pb-8 relative"
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true }}
      transition={{ duration: 0.2, ease: [0.2, 0, 0.38, 0.9] }}
    >
      <div className="h-px bg-[#2a2a2a] mb-4 sm:mb-6 md:mb-8" />
      2026
    </motion.footer>
  )
}
