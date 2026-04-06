"use client"

import { motion } from "framer-motion"
import { siteContent } from "@/lib/site-content"

export const HeroSection = () => {
  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.05,
        delayChildren: 0.05,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        duration: 0.25,
        ease: [0.2, 0, 0.38, 0.9],
      },
    },
  }

  return (
    <section id="hero" className="pt-20 pb-12 md:pt-32 md:pb-20 relative">
      <div className="px-6 md:px-8">
        <motion.div variants={containerVariants} initial="hidden" animate="visible" className="relative">
          <motion.div variants={itemVariants} className="mb-6 md:mb-8">
            <h1 className="text-xl md:text-2xl lg:text-4xl font-normal text-[#fafafa] text-pretty">
              {siteContent.person.name}
            </h1>
          </motion.div>

          <motion.div variants={itemVariants} className="relative">
            <p className="text-base md:text-lg text-[#a1a1a1] max-w-2xl leading-relaxed text-balance">
              {siteContent.person.shortBio}
              <br />
              {siteContent.person.fullBio}
              <br />
              Currently at{" "}
              <a
                href={siteContent.hero.currentRoles[0].url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[#fafafa] underline decoration-[#525252] hover:decoration-[#fafafa] transition-colors duration-300"
              >
                {siteContent.hero.currentRoles[0].company}
              </a>{" "}
              as {siteContent.hero.currentRoles[0].title}.
            </p>
          </motion.div>
        </motion.div>
      </div>
    </section>
  )
}
